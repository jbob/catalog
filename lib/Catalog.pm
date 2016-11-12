package Catalog;
use Mojo::Base 'Mojolicious';
use Mango;
use MongoDB;
use Minion;
use Minion::Backend::MongoDB;
use Minion::Backend::Mango;
use Minion::Backend::Storable;
use Mongoose;
use DateTime;
use DateTime::Format::Strptime;
use Mail::Builder::Simple;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');
  $self->secrets($config->{secrets});

  # All those backend do not yet work with minion 6
  # See cpanfile
  #$self->plugin('Minion', { Storable => $config->{minion_storable} });
  #$self->plugin('Minion', { MongoDB => $config->{mongouri} . "/" . $config->{minion_mongo_database} });
  $self->plugin('Minion', { Mango => $config->{mongouri} . "/" . $config->{minion_mango_database} });

  $self->helper(auth => sub {
      my $con = shift;
      return 1 if $con->session
               and $con->session('logged_in')
               and $con->session('logged_in') == 1;
      return; # Ask for password
  });

  $self->helper(mango => sub {
      state $mango = Mango->new($config->{mongouri});
      my $coll = $mango->db($config->{database})->collection($config->{data_collection});
  });

  $self->helper(mongo => sub {
      state $mongo = MongoDB->connect($config->{mongouri})->get_database($config->{database})->get_collection($config->{data_collection});
  });

  Mongoose->db($config->{database});
  Mongoose->load_schema(search_path => 'Catalog::Model', shorten => 1);

  $self->minion->add_task(send_mail => sub {
      warn "Sending mail!";
      my $job = shift;
      my $id = shift;
      my $book;
      eval {
        $book = Book->find_one({_id => MongoDB::OID->new(value => $id)});
      };
      if ($@) {
          warn $@;
      }
      if($book) {
          my $mail = Mail::Builder::Simple->new;
          eval {
              $mail->send(
                mail_client => {
                    mailer => 'SMTP',
                    mailer_args => $config->{mailer}
                },
                from => 'mail@markusko.ch',
                to => 'mail@markusko.ch',
                subject => $book->title,
                plaintext => $book->title ."\r\n". $book->author
              );
          };
          if ($@) {
              warn $@;
          }
          warn "Mail sent :)";
      } else {
          warn "No result :(";
      }
  });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->any('/login')->to('main#login');
  my $l = $r->under(sub {
      my $self = shift;
      return 1 if $self->auth;
      $self->session(logged_in => 0);
      $self->session(target => $self->req->url->to_abs->path);
      $self->redirect_to('/login');
      return;
  });
  $l->get('/')->to('main#index');
  $l->any('/book/:id')->to('main#book');
  $l->get('/books/:type')->to('main#books');
  $l->get('/mail/:id')->to('main#mail');
}

1;
