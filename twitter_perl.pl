#!/usr/local/perls/perl-5.20.0/bin/perl
# https://api.twitter.com/1.1/search/tweets.json?q=%40twitterapi

use 5.020;
use feature qw(postderef signatures);
no warnings qw(experimental::postderef experimental::signatures);

use utf8;
use open qw(:std :utf8);

use Net::Twitter;
use Data::Dumper;
use Date::Parse;
use POSIX qw(strftime);
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json);

# get your own credentials at https://dev.twitter.com/apps/new
my $nt = Net::Twitter->new(
	ssl      => 1,
	traits   => [qw/OAuth API::RESTv1_1 AutoCursor/],
	map { $_ => $ENV{"twitter_$_"} || die "ENV twitter_$_ not set" }
		qw(
			consumer_secret
			consumer_key
			access_token
			access_token_secret
			)
	);
die "Could not make Twitter object!\n" unless defined $nt;

@ARGV = map { join ' OR ', $_, "#$_" } qw( perl cpan perl6 perl5 );

my $dater = sub {
	state $format = '%Y-%m-%d';
	strftime( $format, localtime( str2time($_[0]) ) )
	};

my %found;

chdir 'results' if -d 'results';
DAYS_AGO: foreach my $offset ( 0 .. 3 ) {
	my $until = strftime( '%Y-%m-%d', localtime( time - $offset * 86400 ) );

	TERM: foreach my $term ( @ARGV ) {
		state $count = 1;
		say $until, " ($term) ", "=" x (60 - length $term);
		my $r = $nt->search( {
			'q'           => $term,
			'until'       => $until,
			'lang'        => 'en',
			'count'       => 100,
			'result_type' => 'recent',
			} );

		my $time = time;
		open my $fh, '>:utf8', "${term}_${until}_${time}.json";
		print { $fh } encode_json( $r );
		close $fh;

		STATUS: foreach my $status ( $r->{statuses}->@* ) {
			next STATUS if killed_user( $status->{user} );

			my $date = $dater->( $status->{created_at} );
			my @urls = map {
				last_location( $_ );
				} $status->{text} =~ m|\b(https?://\S+[^.!:])[\s.!:]|g;
			next STATUS unless @urls;

			foreach my $url ( @urls ) {
				my( $url, $title ) = $url->@*;
				$found{$url}{title} = $title;
				$found{$url}{count} = ++$found{$url}{count};
				$found{$url}{users}{ $status->{user}{screen_name} }++;
				}
			}

		# sleep 2;
		}
	}

foreach my $url ( sort {
	$found{$b}{count} <=> $found{$a}{count}
		||
	$found{$b}{title} <=> $found{$a}{title}
 		} keys %found ) {
	my( $count, $title, $users ) = @{ $found{$url} }{ qw(count title users) };
	say "$count: $url\n\t$title\n\t", join ' ', sort keys %$users;
	}

sub last_location ( $url ) {
	state $ua = Mojo::UserAgent->new;
	state $kill_domains_re = kill_domains();

	while( 1 ) {
		my $location = $ua->get( $url )->res->headers->header( 'Location' );
		last unless $location =~ m|https?://|;
		$url = $location;
		}

	return if grep { $url =~ m/\Q$_/i } qw(
		moaning-black-perl-fucked-well
		);

	my $url = Mojo::URL->new( $url );
	my( $domain ) = $url->host =~ m/([^.]+ \. [^.]+) \z/x;
	# say "$url -> $domain";
	if( $domain =~ $kill_domains_re ) {
		# say "\tkilled domain";
		return;
		}

	my $tx = $ua->get( $url );
	return unless $tx->success;
	my( $title ) = $tx->res->dom->find('title')->map('text')->each;
	$title =~ s/\A\s+|\s+\z//g;

	return [ $url, $title ];
	}

sub kill_domains {
	my $str = join '|', qw(
			hostwinds.com
			kinkstew.com
			kloud51.com
			ampps.com
			bullhornreach.com
			whorecircus.com
			kinkydistrict.com
			tittypies.com
			pornpeacock.com
			houseofthewicked.com
			usfreedomarmy.com
			ziprecruiter.com
			gekoo.co
			force.com
			jobviewtrack.com
			ebid.net
			freelancer.com
			careerjet.co.in
			spanjobs.com
			findmjob.com
			playboy.com
			satriani.com
			greenwhore.com
			untappd.com
			);

	qr{ (?:$str) \z }xi;
	}

sub killed_user ( $user ) {
	return grep { $user eq $_ } qw(
		briandfoy_perl
		JobloreUK
		KaceyOneill
		);
	}

__END__

Parameters: q, callback, lang, locale, rpp, page, since_id, until, geocode, show_user, result_type

          'search_metadata' => {
                                 'max_id_str' => '597940758071496704',
                                 'completed_in' => '0.028',
                                 'since_id_str' => '0',
                                 'refresh_url' => '?since_id=597940758071496704&q=python&include_entities=1',
                                 'count' => 15,
                                 'since_id' => 0,
                                 'next_results' => '?max_id=597939636732821503&q=python&include_entities=1',
                                 'query' => 'python',
                                 'max_id' => '597940758071496704'
                               }


                {
                            'text' => 'Indonesia adalah Tempat ditemukannya ular terpanjang di dunia yaitu, Python Reticulates sepanjang 10 meter di Sulawesi.',
                            'favorited' => $VAR1->{'statuses'}[0]{'favorited'},
                            'in_reply_to_user_id_str' => undef,
                            'entities' => {
                                            'user_mentions' => [],
                                            'urls' => [],
                                            'symbols' => [],
                                            'hashtags' => []
                                          },
                            'in_reply_to_screen_name' => undef,
                            'in_reply_to_user_id' => undef,
                            'geo' => undef,
                            'in_reply_to_status_id' => undef,
                            'retweeted' => $VAR1->{'statuses'}[0]{'favorited'},
                            'coordinates' => undef,
                            'metadata' => {
                                            'result_type' => 'recent',
                                            'iso_language_code' => 'in'
                                          },
                            'truncated' => $VAR1->{'statuses'}[0]{'favorited'},
                            'created_at' => 'Tue May 12 01:42:31 +0000 2015',
                            'retweet_count' => 0,
                            'contributors' => undef,
                            'id_str' => '597939880635682816',
                            'favorite_count' => 0,
                            'place' => undef,
                            'user' => {
                                        'default_profile_image' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'followers_count' => 689,
                                        'is_translator' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'location' => 'SMAN4 B.LAMPUNG',
                                        'profile_banner_url' => 'https://pbs.twimg.com/profile_banners/318389171/1374290316',
                                        'time_zone' => 'Bangkok',
                                        'profile_link_color' => 'D43560',
                                        'friends_count' => 817,
                                        'favourites_count' => 159,
                                        'screen_name' => 'Risaameliaputri',
                                        'is_translation_enabled' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'url' => undef,
                                        'profile_background_color' => '6435A6',
                                        'notifications' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'protected' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'utc_offset' => 25200,
                                        'profile_sidebar_fill_color' => '99CC33',
                                        'description' => "\x{2665}\@SMANPAT_BDL \x{2665}\@yandapangestu",
                                        'lang' => 'id',
                                        'profile_image_url' => 'http://pbs.twimg.com/profile_images/378800000168654537/acc506d6089981424a987b783950382d_normal.jpeg',
                                        'geo_enabled' => $VAR1->{'statuses'}[0]{'user'}{'profile_use_background_image'},
                                        'listed_count' => 1,
                                        'profile_use_background_image' => $VAR1->{'statuses'}[0]{'user'}{'profile_use_background_image'},
                                        'name' => 'Risa',
                                        'entities' => {
                                                        'description' => {
                                                                           'urls' => []
                                                                         }
                                                      },
                                        'verified' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'profile_background_image_url_https' => 'https://pbs.twimg.com/profile_background_images/378800000010007298/d06e7c9aefed12e3efe3a75b3bfa88cd.jpeg',
                                        'follow_request_sent' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'profile_image_url_https' => 'https://pbs.twimg.com/profile_images/378800000168654537/acc506d6089981424a987b783950382d_normal.jpeg',
                                        'profile_text_color' => '3E4415',
                                        'default_profile' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'profile_sidebar_border_color' => 'FFFFFF',
                                        'following' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'contributors_enabled' => $VAR1->{'statuses'}[0]{'favorited'},
                                        'created_at' => 'Thu Jun 16 12:17:13 +0000 2011',
                                        'id_str' => '318389171',
                                        'profile_background_tile' => $VAR1->{'statuses'}[0]{'user'}{'profile_use_background_image'},
                                        'statuses_count' => 33212,
                                        'id' => 318389171,
                                        'profile_background_image_url' => 'http://pbs.twimg.com/profile_background_images/378800000010007298/d06e7c9aefed12e3efe3a75b3bfa88cd.jpeg'
                                      },
                            'source' => '<a href="http://twittbot.net/" rel="nofollow">twittbot.net</a>',
                            'lang' => 'in',
                            'in_reply_to_status_id_str' => undef,
                            'id' => '597939880635682816'
                          },
