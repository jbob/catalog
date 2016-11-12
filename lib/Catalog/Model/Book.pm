package Catalog::Model::Book;
use Moose;
with 'Mongoose::Document';

has title => ( is => 'rw', isa => 'Str');
has author => ( is => 'rw', isa => 'Str');
has genres => ( is => 'rw', isa => 'ArrayRef[Str]');
has price => (is => 'rw', isa => 'Num');
has pub_date => (is => 'rw', isa => 'DateTime');

1;
