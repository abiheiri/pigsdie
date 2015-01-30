#!/usr/bin/perl

use strict;
use warnings;

sub prompt {
	my ($message, $options) = @_;
	print "$message [", join("/", @$options), "]\n";

	my $valid = join "|", sort { length $b <=> length $a } @$options;
	$valid = qr/^(?:$valid)$/i;

	my $response = <>;
	chomp $response;
	until ($response =~ $valid) {
		print "'$response' is not valid. Please choose one of [", join("/", @$options), "]\n";
		$response = <>;
		chomp $response;
	}

	return $response;
}

sub insult {
	my $category = shift;

	my %categories = (
		stealth => [
			"you move like a bloated cow",
			"smooth move Usain Bolt",
		],
		
		purchase => [
			"you lack the sufficient funds",
			"you dont have that kinda cash",
			"moron, you dont have that kinda \$\$\$",
		],
	
		sell => [
			"Im sorry, you cant make shit put of thin air",
			"you dont have that item, you fuck stick",
			"fuck outta here, you dont have any available",
		],
		
		wrong_key => [
			"Apparently you're an idiot who doesnt know how to press the correct key",
			"Man you are stupid, you pressed some useless key",
			"PEBCAK",
			"Please press a valid key",
		],
	);

	my $insults = $categories{$category};

	my $insult = $insults->[ rand @$insults ];

	print "$insult\n";
}

sub check_stats {
	my $player = shift;

	if ($player->{wanted} > 50) {
		print "Police are on your tail!\n\n[A] Shoot them back ?\n[B] Go into hiding ?\n";
		my $be_a_hero_or_bitch = prompt "What would you like to do?", [ "a", "b" ];

		if ($be_a_hero_or_bitch =~ /a/i) {
			fight_pigs($player);
		} else {
			if (rand() <= $player->{stealth}) {
				$player->{wanted} -= 5;
				print "You escape!\n";
				$player->{wanted} = 0;
			} else {
				insult("stealth");
				fight_pigs($player);
			}
		}
	}
}

sub fight_pigs {
	my $player = shift;

	my $pigs = 3 + int rand 6;

	my $keep_fighting = "y";
	while ($pigs and $keep_fighting =~ /y/i) {
		#player fires
		if (rand() <= $player->{fighting}) {
			print "You hit one of the officiers!\n";
			$pigs--;
		} else {
			print "You suck, hit the target range\n";
		}

		#cops fire
		if (rand() <= (1 - $player->{evasion})) {
			print "Police shot your bitch ass! Go to the gym and play dodge ball\n";
			$player->{health} -= 10;
			if ($player->{health} <= 0) {
				print "You are dead\n";

				last; #you can't fight if you are dead
			} else {
		       		print "You have $player->{health} health left.\n";

				if (rand() > $player->{coolness}) {
					my @drugs = grep { $player->{coat}{$_} } keys %{ $player->{coat} };
					#can't drop what you don't have
					if (@drugs) {
						my $drug    = $drugs[ rand @drugs ];
						my $holding = $player->{coat}{$drug};
						my $amount  = int rand $holding/2;
						$player->{coat}{$drug} -= $amount;

						print "shit you dropped $amount $drug\n";
					}
				}

			}
		}

		$keep_fighting = prompt "Want to keep fighting?\n", [ "y", "n" ];

		if ($keep_fighting =~ /n/i) {
			if (rand() <= $player->{stealth}) {
				print "You got away!\n";
				$player->{wanted} = 0;
			} else {
				insult("stealth");
				$keep_fighting = "y";
			}
		}
	}
}

#you should move this to main();
my $player = {
	days	 => 0,
	health   => 100,
	wanted   => 0,
	stealth  => .50,
	fighting => .50,
	evasion  => .50,
	coolness => .50,
	mycash	 => 1000,
	coat   => {
		cocaine  => 0,
		maryjane => 0,
		lsd      => 0,
		shrooms  => 0,
		skooma  => 0,
	},
};



sub goto_inventory
{
	print "YOUR STATS\n==========\n"
	#print "Key: $_ and Value: $player{$_}\n" foreach (keys$player);
}

sub goto_buy
{
	my %costs = ( 
		maryjane => int rand 300,
		skooma => int rand 100,
		shrooms => 10 + int rand 90,
		lsd => 100 + int rand 50,
		cocaine => 1000 + int rand 20000,
	  );

	$player->{days}++;

	print "Day: $player->{days}\n", "====\n", "Welcome to the silkroad, below are current market prices...\n";


	my @valid_drugs = grep { $costs{$_} > 5 } sort keys %costs;

	for my $drug (@valid_drugs)
	{
		print "$drug: $costs{$drug}\n"
	}


	if ($costs{cocaine} < 10000)
	{
		print "Looks like the chinese flooded the market with cheap coke, prices bottomed out!\n";
	}
	 
	#regex to match any valid drug, it is reverse sorted by length to avoid a
	#problem where a substring matches instead of the whole string.  It isn't a
	#problem currently, but it can become one if you, for instance, have lsd and
	#lsd-super.  If the alternation looks like "lsd-super" =~ /(lsd|lsd-super)/
	#then you will match lsd not lsd-super like you want.  So the regex must look
	#like /lsd-super|lsd/, you achieve this by reverse sorting on the length (ie
	#long strings go first in the alternation)
	my $valid_drug_regex = join "|", sort { length($b) <=> length($a) } @valid_drugs;
	$valid_drug_regex = qr/$valid_drug_regex/;
	 
	print "purchase drugs [@valid_drugs]: \(type \"quit\" at any time to exit\)\n";
	while (my $line = <>) {
		chomp $line;
		my ($amount, $drug) = $line =~ / ([0-9]{1,6}) \s+ ($valid_drug_regex) /x;

		if ($line eq "quit" or $line eq "q" )
		{
			main ();
			return;
		}

		unless (defined $amount and defined $drug) {
			print "I don't understand: [$line]\n",
				"valid drugs are: @valid_drugs\n",
				"purchase drugs by saying 'amount drug'\n";
			next;
		}
	
		my $cost = $amount * $costs{$drug};
		if ($player->{mycash} < $cost)
		{
		       insult("purchase");
		       print " for $amount $drug\n";
		}
		else
		{
		       $player->{mycash} = $player->{mycash} - $cost;
		       $player->{coat}{$drug} = $player->{coat}{$drug} + $amount;
		       $player->{wanted}++;
		       print "you purchased $amount $drug\n";
	       }	

	}
}

sub goto_sell
{
	my %costs = ( 
		maryjane => int rand 300,
		skooma => int rand 100,
		shrooms => 10 + int rand 90,
		lsd => 100 + int rand 50,
		cocaine => 1000 + int rand 20000,
	  );

	$player->{days}++;

	print "Day: $player->{days}\n", "====\n", "Welcome to the silkroad, below are current market prices...\n";


	my @valid_drugs = grep { $costs{$_} > 5 } sort keys %costs;

	for my $drug (@valid_drugs)
	{
		print "$drug: $costs{$drug}\n"
	}


	if ($costs{cocaine} < 10000)
	{
		print "Looks like the chinese flooded the market with cheap coke, prices bottomed out!\n";
	}
	 
	my $valid_drug_regex = join "|", sort { length($b) <=> length($a) } @valid_drugs;
	$valid_drug_regex = qr/$valid_drug_regex/;
	 
	print "sell drugs [@valid_drugs]: \(type \"quit\" at any time to exit\)\n";
	while (my $line = <>) {
		chomp $line;
		my ($amount, $drug) = $line =~ / ([0-9]{1,6}) \s+ ($valid_drug_regex) /x;

		if ($line eq "quit" or $line eq "q" )
		{
			main ();
			return;
		}

		unless (defined $amount and defined $drug) {
			print "I don't understand: [$line]\n",
				"valid drugs are: @valid_drugs\n",
				"sell drugs by saying 'amount drug'\n";
			next;
		}
	
		my $cost = $amount * $costs{$drug};
		if ($player->{coat}{$drug} <= 0)
		{
		       insult("sell");
		       print " for $amount $drug\n";
		}
		else
		{

			$player->{mycash} = $player->{mycash} + $cost;
			$player->{coat}{$drug} = $player->{coat}{$drug} - $amount;
			$player->{wanted}++;
			print "you sold $amount $drug\n";
		}
	}
}


		
sub goto_debug
{
	print "Shell\$:";

        my @valid_drugs = qw(
                cash
                health
                wanted
        );

        my $valid_drug_regex = join "|", sort { length($b) <=> length($a) } @valid_drugs;
        $valid_drug_regex = qr/$valid_drug_regex/;

        while (my $line = <>) {
                chomp $line;
                my ($amount, $drug) = $line =~ / ([0-9]{1,6}) \s+ ($valid_drug_regex) /x;
	
		if ($line eq "quit" )
                {
                        main ();
                        last;
                }

                unless (defined $amount and defined $drug) {
			insult("wrong_key");
                        next;
                }
		
		if ( $drug eq "cash"){ $player->{mycash} = $amount; }
		elsif ( $drug eq "health"){ $player->{health} = $amount; }
		elsif ( $drug eq "wanted"){ $player->{wanted} = $amount; }
                

	}
}

sub main
{

	my %dispatch = (
	 r => sub { print "not implemented\n" },
	 b => \&goto_buy,
	 s => \&goto_sell,
	 );

	my $option; 

	do {
		if ($player->{days} >= 30 or $player->{health} <= 0) {
			print "GaMe OvEr!\n ====\n You've reached $player->{days} days\n";
			goto_inventory();
			last;
		}

		if ($player->{wanted} > 50) { #get hassled by the cops each day
		check_stats($player);
		};

		redo if $player->{wanted} > 75; #now you can only be hassled by the cops
		
		goto_inventory();

		print "===Main Menu===\n [r] rob a bank for some money\n [b] buy drugs\n [s] sell drugs\n [q] QUIT game\n";

		$option = prompt "What would you like to do?", [ "r", "b", "s", "q" ];

		if (exists $dispatch{$option}) {
			$dispatch{$option}->($player);
		}

	}
}

print "\n~~~~~~WELCOME TRAVELER! ~~~~~~~\n\n";
main ();
