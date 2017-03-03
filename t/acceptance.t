use Mojo::Base -strict;

use JSON::Validator;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json decode_json );
use Mojo::Util qw(dumper encode);
use Test::Mojo;
use Test::More;

plan skip_all => 'cpanm Test::JSON::Schema::Acceptance'
  unless eval 'use Test::JSON::Schema::Acceptance; 1';

my ($t, $host_port, $opts);
my @drafts = qw(4);                              # ( 3 4 )
my %schemas = map { (path($_)->basename, $_) }
  path(path($INC{"Test/JSON/Schema/Acceptance.pm"})->dirname)->list_tree->each;

use Mojolicious::Lite;
get '/*file' => sub {
  my $c    = shift;
  my $file = Mojo::File->new($c->stash('file'))->basename;
  return $c->reply->not_found("Could not find $file") unless $schemas{$file};
  return $c->render(text => $schemas{$file}->slurp);
};

$t = Test::Mojo->new;
$t->get_ok('/folderInteger.json')->status_is(200);
$host_port = $t->ua->server->url->host_port;

$opts = {
  only_test  => $ENV{ACCEPTANCE_TEST},
  skip_tests => [
    'dependencies',    # TODO
  ],
};

for my $draft (@drafts) {
  my $accepter = Test::JSON::Schema::Acceptance->new($draft);

  $accepter->acceptance(
    sub {
      my $schema = normalize_schema(shift);
      my $input  = decode_json(encode 'UTF-8', shift);
      my @errors = eval {
        JSON::Validator->new->ua($t->ua)->load_and_validate_schema($schema)->validate($input);
      };

      note(dumper([$input, $schema, $@ || @errors])) if $ENV{ACCEPTANCE_TEST};
      die $@ if $@;
      return @errors ? 0 : 1;
    },
    $opts,
  );
}

done_testing();

sub normalize_schema {
  my $str = encode_json(shift);
  $str =~ s!http\W+localhost:1234\b!http://$host_port!;
  return decode_json($str);
}
