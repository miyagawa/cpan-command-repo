package CPAN::Command::Repo;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use CPAN;
use URI;

push @CPAN::Complete::COMMANDS, qw( repo );
$CPAN::Shell::Help->{repo} = "open a subshell by checking out a ditribution's code repository";

sub CPAN::Shell::repo  { shift->rematein("repo", @_) }
sub CPAN::Module::repo { shift->rematein("repo") }

sub CPAN::Distribution::repo {
    my $self = shift;
    $self->get;
    my $package = $self->called_for;

    my $meta = $self->parse_meta_yml;
    my $repo = $meta->{resources}{repository}
        or return $CPAN::Frontend->mywarn("$package doesn't have a repository set in META.yml");

    my $pwd = CPAN::anycwd();
    my $dir = File::Spec->catfile($CPAN::Config->{cpan_home}, 'repo');
    mkdir $dir, 0777 unless -e $dir;

    chdir($dir) or $CPAN::Frontend->mydie("Can't chdir to $dir");

    do_checkout(URI->new($repo), $package);
    $self->safe_chdir($pwd);
}

sub do_checkout {
    my($repo, $package) = @_;
    $package =~ s/::/-/g;

    if (-e $package && -d _) {
        my $ans = ExtUtils::MakeMaker::prompt("$package aleady exists. Remove it before checking out?", "yes");
        if ($ans =~ /^[Yy]/) {
            File::Path::rmtree($package);
        }
    }

    my $chdir_to;
    if ($repo->scheme eq 'git' or $repo->path =~ /\.git$/) {
        !system "git", "clone", $repo, $package
            or $CPAN::Frontend->mydie("Can't git clone $repo");
        $chdir_to = $package;
    } elsif ($repo->scheme eq 'svn' or $repo->path =~ /trunk|branches/) { # FIXME
        !system "svn", "checkout", $repo, $package
            or $CPAN::Frontend->mydir("Can't svn checkout $repo");
        $chdir_to = $package;
    }
    # CVS, Darcs, bzr, hg
    else {
        $CPAN::Frontend->mywarn("Can't get repository type of $repo");
    }

    if ($chdir_to) {
        chdir $chdir_to or $CPAN::Frontend->mydie("Can't chdir to $chdir_to");
        my $shell = CPAN::HandleConfig->safe_quote($CPAN::Config->{'shell'});
        system $shell;
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

CPAN::Command::Repo - Adds new 'repo' command to CPAN shell

=head1 SYNOPSIS

  perl -MCPAN::Command::Repo -e 'CPAN::shell()'
  cpan> repo Module

=head1 DESCRIPTION

CPAN::Command::Repo is a plugin to CPAN.pm that adds a new command
I<repo> to check out (or I<clone>) module's source code repository so
that you can look at what's been changed or hack on patches and send
it back.

Currently this module supports I<git> and I<subversion>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN>, L<Module::Install::Repository>

=cut
