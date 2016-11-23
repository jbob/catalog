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
    my $args;

    my @res = Book->find->all;
    $args->{result} = \@res;
    $self->render(args => $args);
    return;
}

sub book {
    my $self = shift;
    my $stash = $self->stash;
    my $id = $stash->{id};
    my $params = $self->req->params->to_hash;
    my $submit = $params->{submit};
    delete $params->{submit};

    # Delete empty params, otherwise defaults from the Book model
    # do not kick in
    for my $p (keys %$params) {
        delete $params->{$p} if not $params->{$p};
        if (ref $params->{$p} eq 'ARRAY') {
            # Only keep non empty
            $params->{$p} = [ grep { $_ ne '' } @{ $params->{$p} } ];
            delete $params->{$p} if not @{ $params->{$p} };
        }
        if (ref $params->{$p} eq 'HASH') {
            # WIP
            delete $params->{$p} if not %{ $params->{$p} };
        }

    }

    if($submit) {
        my $id;
        # Store a new book
        # Here Mongoose checks the values against our data model
        # We need to convert pub_date from String to a DateTime object, of
        # validation fails
		my $author = Author->new({ name => $params->{author}, gender => 'f'});
		$params->{author} = $author;
        my $book = Book->new($params);
        $id = $book->save();
        $self->redirect_to("/");
        return;
    } else {
        if($id eq 'new') {
            # Display edit form
            $self->render('main/edit');
            return;
        }
        # List book details
        my $res;
        $res = Book->find_one({_id => MongoDB::OID->new(value => $id)});
        $self->render(text => $res->nice_text);
        return;
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
