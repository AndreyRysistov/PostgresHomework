#!/usr/bin/perl -w


while (<STDIN>)
{
  chomp;
  my ( $num, $descr ) = $_ =~ /^(\d+)\.\s*(.+)$/; 
  print $num . "\t" . $descr . "\n";
}

exit( 0 );
