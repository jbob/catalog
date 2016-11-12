package Catalog::Model::Book;
use Moose;
with 'Mongoose::Document';

has title => ( is => 'rw', isa => 'Str', required => 1);
has author => ( is => 'rw', isa => 'Str', required => 1);
has genres => ( is => 'rw', isa => 'ArrayRef[Str]', required => 0);
has price => (is => 'rw', isa => 'Num', default => 23.42);
has pub_date => (is => 'rw', isa => 'DateTime', required => 0);

1;
