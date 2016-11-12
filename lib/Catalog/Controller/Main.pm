package Catalog::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;

  $self->render();
}

sub login {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $password = $self->param('password');
    if($password and $password eq $config->{password}) {
        # Received login form with valid password
        $self->session(logged_in => 1);
        $self->redirect_to($self->session('target') || '/');
        return;
    }
    $self->render; # Send login form
}

sub books {
    my $self = shift;
    my $stash = $self->stash;
    my $type = $stash->{type};
    my $args;
    $args->{type} = $type;

    my $result;
    if ($type eq 'mango') {
        $result = $self->mango->find->all;
        for my $r (@$result) {
            $r->{pub_date} = DateTime->from_epoch(epoch => $r->{pub_date}->to_epoch);
        }
    }
    if ($type eq 'mongo') {
        my @res = $self->mongo->find->all;
        $result = \@res;
    }
    if ($type eq 'mongoose') {
        my @res = Book->find->all;
        my $result = \@res;
        $args->{result} = $result;
        $self->render('main/books-mongoose', args => $args);
        return;
    }
    $args->{result} = $result;
    $self->render(args => $args);
}

sub book {
    my $self = shift;
    my $stash = $self->stash;
    my $id = $stash->{id};
    my $params = $self->req->params->to_hash;
    my $type = $params->{type};
    delete $params->{type};
    my $submit = $params->{submit};
    delete $params->{submit};

    # Delete empty params, otherwise defaults from the Book model
    # do not kick in
    for my $p (keys %$params) {
        delete $params->{$p} if not $params->{$p};
    }

    if($submit) {
        my $id;
        # Store a new book
        # Currently now editing
        delete $params->{submit};
        if($submit =~ /Mango$/) {
            # We should check here if our data model is honored
            # But that is what Mongoose is for
            my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', on_error => 'croak');
            $params->{pub_date} = $format->parse_datetime($params->{pub_date});;
            $id = $self->mango->insert($params);
        }
        if($submit =~ /MongoDB$/) {
            # We should check here if our data model is honored
            # But that is what Mongoose is for
            my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', on_error => 'croak');
            $params->{pub_date} = $format->parse_datetime($params->{pub_date});;
            my $res = $self->mongo->insert_one($params);
            $id = $res->inserted_id;
        }
        if($submit =~ /Mongoose$/) {
            # Here Mongoose checks the values against our data model
            # We need to convert pub_date from String to a DateTime object, of
            # validation fails
            my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', on_error => 'croak');
            $params->{pub_date} = $format->parse_datetime($params->{pub_date});;
            warn ref $params->{pub_date};
            my $book = Book->new($params);
            $id = $book->save();
        }
        $self->redirect_to("/");
        return;
    } else {
        warn $type;
        warn $id;
        if($id eq 'new') {
            # Display edit form
            $self->render('main/edit');
            return;
        }
        # List book details
        my $res;
        if($type eq 'mango') {
            $res = $self->mango->find_one(Mango::BSON::ObjectID->new($id));
            $self->render(text => $res->{title});
            return;
        }
        if($type eq 'mongo') {
            $res = $self->mongo->find_one({_id => MongoDB::OID->new(value => $id)});
            $self->render(text => $res->{title});
            return;
        }
        if($type eq 'mongoose') {
            $res = Book->find_one({_id => MongoDB::OID->new(value => $id)});
            $self->render(text => $res->title);
            return;
        }
    }
};

sub mail {
    my $self = shift;
    my $stash = $self->stash;
    my $id = $stash->{id};

    # For now only via Mongoose
    $self->minion->enqueue(send_mail => [$id]);
    $self->render(text => "You'll receive a mail shortly");
}

1;
