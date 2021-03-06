#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Deep;
use Test::Exception;

use TestSchema;
my $schema = TestSchema->deploy_or_connect();
$schema->prepopulate;

my $rs = $schema->resultset('Foo')->search({ id => 1 });
my $rs2 = $schema->resultset('Foo')->search({ id => { '>=' => 3 } });


#cmp_deeply [ map $_->id, $rs2->union($rs)->all ], [1, 3, 4, 5],
   #'union returns correct values';

dies_ok {
   my $rs3 = $rs->search(undef, { columns => ['id'] });
   $rs->union($rs3) ;
} 'unioning differing ColSpecs dies';

dies_ok { $rs->union($schema->resultset('Bar')) } 'unioning differing ResultSets dies';

{
   my $rs3 = $rs->search(undef, {
      columns => ['id'],
      '+select' => [\'"foo" as station'],
      '+as'     => ['station'],
   });
   my $rs4 = $schema->resultset('Bar')->search(undef, {
      columns => ['id'],
      '+select' => [\'"bar" as station'],
      '+as'     => ['station'],
   });
   $rs3->result_class('DBIx::Class::ResultClass::HashRefInflator');
   $rs4->result_class('DBIx::Class::ResultClass::HashRefInflator');
   my $rs5 = $rs3->union($rs4);
   lives_ok { [ $rs5->all ] }
      q{unioning differing ResultSets does not die when you know what you're doing};
}

done_testing;
