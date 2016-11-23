package Catalog::Model::Types;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Gender',
     as 'Str',
  where { $_ eq 'f' || $_ eq 'm' },
message { "Gender must be 'f' or 'm', not $_!" };

subtype 'DTfromStr',
     as 'DateTime';

coerce 'DTfromStr',
  from 'Str',
   via {
        my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', on_error => 'croak');
        $format->parse_datetime($_);
       };
1;
