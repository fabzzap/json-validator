use lib '.';
use t::Helper;

my $validator = JSON::Validator->new;
my $schema = {anyOf => [{type => "string", maxLength => 5}, {type => "number", minimum => 0}]};

validate_ok 'short',    $schema;
validate_ok 'too long', $schema, E('/', 'anyOf[0]: String is too long: 8/5.');
validate_ok 12,         $schema;
validate_ok - 1, $schema, E('/', 'anyOf[1]: -1 < minimum(0)');
validate_ok {}, $schema, E('/', 'Expected string or number, got object.');

# anyOf with explicit integer (where _guess_data_type returns 'number')
my $schemaB = {anyOf => [{type => "integer"}, {minimum => 2}]};
validate_ok 1, $schemaB;

validate_ok(
  {type => 'string'},
  {
    properties => {
      type => {
        anyOf => [
          {'$ref' => '#/definitions/simpleTypes'},
          {
            type        => 'array',
            items       => {'$ref' => '#/definitions/simpleTypes'},
            minItems    => 1,
            uniqueItems => Mojo::JSON::true,
          }
        ]
      },
    },
    definitions => {simpleTypes => {enum => [qw(array boolean integer null number object string)]}}
  }
);

# anyOf with nested anyOf
$schema = {
  anyOf => [
    {
      anyOf => [
        {
          type                 => 'object',
          additionalProperties => false,
          required             => ['id'],
          properties           => {id => {type => 'integer', minimum => 1}},
        },
        {
          type                 => 'object',
          additionalProperties => false,
          required             => ['id', 'name', 'role'],
          properties           => {
            id   => {type => 'integer', minimum => 1},
            name => {type => 'string'},
            role => {anyOf => [{type => 'string'}, {type => 'array'}]},
          },
        }
      ]
    },
    {type => 'integer', minimum => 1}
  ]
};

validate_ok {id => 1, name => '', role => 123}, $schema,  E('/role', 'anyOf[0.1]: Expected string or array, got number.');
validate_ok 'string not integer', $schema, E('/', 'Expected integer or object, got string.');
validate_ok {id => 1, name => 'Bob'}, $schema, E('/role', 'anyOf[0.1]: Missing property.');
validate_ok {id => 1, name => 'Bob', role => 'admin'}, $schema;

validate_ok {foo => 1}, $schema, (
    E('/', 'anyOf[0.0]: Properties not allowed: foo.'),
    E('/', 'anyOf[0.1]: Properties not allowed: foo.')
);

validate_ok {}, $schema,
  (
    E('/id',   'anyOf[0.0]: Missing property.'),
    E('/id',   'anyOf[0.1]: Missing property.'),
    E('/name', 'anyOf[0.1]: Missing property.'),
    E('/role', 'anyOf[0.1]: Missing property.'),
);

$schema = {
    '$schema'   => 'http://json-schema.org/draft-04/schema#',
    type        => 'object',
    title       => 'test',
    description => 'test',
    properties  => {age => {type => 'number', anyOf => [{multipleOf => 5}, {multipleOf => 3}]}}
};

validate_ok {age => 6 }, $schema;
done_testing;
