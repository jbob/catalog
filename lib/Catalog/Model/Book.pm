package Catalog::Model::Book;
use Moose;
use Moose::Util::TypeConstraints;
with 'Mongoose::Document';

subtype 'DTfromStr',
     as 'DateTime';

coerce 'DTfromStr',
  from 'Str',
   via {
	    my $input = shift;
        my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', on_error => 'croak');
        return $format->parse_datetime($input);
       };

has title => ( is => 'rw', isa => 'Str', required => 1);
has author => ( is => 'rw', isa => 'Str', required => 1);
has genres => ( is => 'rw', isa => 'ArrayRef[Str]', required => 0);
has price => (is => 'rw', isa => 'Num', default => 23.42);
has pub_date => (is => 'rw', isa => 'DTfromStr', coerce => 1, required => 0);

sub nice_text {
  my $self = shift;
  my $output = sprintf "%s was written by %s and costs %s", $self->title, $self->author, $self->price;
  if($self->pub_date) {
    my $date = $self->pub_date->strftime("%Y");
    $output .= sprintf " it as written in %s", $date;
  }
  return $output;
}

1;
