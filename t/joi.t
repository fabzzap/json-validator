use lib '.';
use t::Helper;
use JSON::Validator 'jv';
use Test::More;

is_deeply(
  jv->object->props(
    age   => jv->integer->min(0)->max(200),
    email => jv->string->email->required,
    name  => jv->string->min(1),
    color => jv->string->min(2)->max(12)->regex('^\w+$'),
    )->TO_JSON,
  {
    type       => 'object',
    required   => ['email'],
    properties => {
      age   => {type => 'integer', minimum   => 0, maximum   => 200},
      color => {type => 'string',  minLength => 2, maxLength => 12, pattern => '^\w+$'},
      email => {type => 'string', format    => 'email'},
      name  => {type => 'string', minLength => 1},
    },
  },
  'generated correct schema'
);

jv_ok(
  {age => 34, email => 'jhthorsen@cpan.org', name => 'Jan Henning Thorsen',},
  jv->props(
    age   => jv->integer->min(0)->max(200),
    email => jv->string->email->required,
    name  => jv->string->min(1),
  ),
);

jv_ok(
  {age => -1, name => 'Jan Henning Thorsen',},
  jv->props(
    age   => jv->integer->min(0)->max(200),
    email => jv->string->email->required,
    name  => jv->string->min(1),
  ),
  E('/age',   '-1 < minimum(0)'),
  E('/email', 'Missing property.'),
);

done_testing;
