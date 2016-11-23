package Catalog::Model::Author;
use Moose;
use Catalog::Model::Types;
with 'Mongoose::Document';


has name => ( is => 'rw', isa => 'Str', required => 1);
has gender => ( is => 'rw', isa => 'Gender', required => 1);
has birthdate => ( is => 'rw', isa => 'DTfromStr', required => 0);

1;
