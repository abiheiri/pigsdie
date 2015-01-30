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
		
		wrong_key => [
			"Apparently you're an idiot who doesnt know how to press the correct key",
			"Man you are stupid, you pressed some useless key",
			"PEBCAK",
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

sub main
{
	while ($player->{health} > 0 and $player->{wanted} > 50) {
		check_stats($player);
	};

	print "What would you like to do?\n [i] check inventory\n [r] rob a bank for some money\n [b] buy drugs\n [s] sell drugs\n [q] QUIT game\n";
	my $option = <>;
	chomp ($option);

	if ($option eq "shell")
	{
		goto_debug();
	}
	elsif ($option =~ /^i/i)
	{
		display_inventory();
		$option = <>;
		main ();
	}
	elsif ($option =~ /^r/i)
	{
		print "not implemented\n";
		main();
	}
	elsif ($option =~ /^b/i)
	{
		goto_buy ();
	}
	elsif ($option =~ /^s/i)
	{
		print "not implemented\n";
		#goto_sell ();
	}
	elsif ($option =~ /^q/i)
	{
		exit;
	}
	else
	{
		insult("wrong_key");
		main ();
	}	
}


sub display_inventory
{
                print <<EOF;
                YOUR STATS
                ==========
                Health: $player->{health}
		Cash: $player->{mycash}
                Wanted Level: $player->{wanted}
                
                Stealth: $player->{stealth}
                Fight:  $player->{fighting}
                Evasion: $player->{evasion}
                

                Your Coat
                =========
		cocaine: $player->{coat}{cocaine}
                maryjane: $player->{coat}{maryjane}
                lsd: $player->{coat}{lsd}
                shrooms: $player->{coat}{shrooms}
                skooma:  $player->{coat}{skooma}
EOF
}

sub goto_buy
{
	my $mj = int rand 300;
	my $skooma = int rand 100;
	my $shrooms = int rand 100;
	my $lsd = int rand 100;
	my $cocaine = int rand 20000;

	$player->{days}++;

	print <<EOF;
	
	Day: $player->{days}
	====
	Welcome to the silkroad, below are current market prices...

	cocaine: $cocaine
	lsd: $lsd
	maryjane: $mj
	shrooms: $shrooms
	skooma: $skooma
	

EOF

	if ($cocaine < 10000)
	{
		print "Looks like the chinese flooded the market with cheap coke, prices bottomed out!\n";
	}

	#list of valid drugs
	my @valid_drugs = qw(
		cocaine
		maryjane
		lsd
		shrooms
		skooma
	);
	 
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

		if ($line eq "quit" )
		{
			main ();
			last;
		}

		unless (defined $amount and defined $drug) {
			print "I don't understand: [$line]\n",
				"valid drugs are: @valid_drugs\n",
				"purchase drugs by saying 'amount drug'\n";
			next;
		}
		

		if ( $drug eq "cocaine")
		{
			my $cost = $amount * $cocaine;
			if ($player->{mycash} < $cost)
			{
				insult("purchase");
				print " for $amount $drug\n";
			}
			else
			{
				$player->{mycash} = $player->{mycash} - $cost;
				$player->{coat}{cocaine} = $player->{coat}{cocaine} + $amount;
				$player->{wanted}++;
				print "you purchased $amount $drug\n";
			}
		}
		elsif ( $drug eq "maryjane")
		{
			my $cost = $amount * $mj;
			if ($player->{mycash} < $cost)
			{
				print "You lack the funds to buy $amount $drug\n";
			}
			else
			{
				$player->{mycash} = $player->{mycash} - $cost;
				$player->{coat}{maryjane} = $player->{coat}{maryjane} + $amount;
				$player->{wanted}++;
				print "you purchased $amount $drug\n";
			}
		}
		elsif ( $drug eq "lsd")
		{
			my $cost = $amount * $lsd;
			if ($player->{mycash} < $cost)
			{
				print "You lack the funds to buy $amount $drug\n";
			}
			else
			{
				$player->{mycash} = $player->{mycash} - $cost;
				$player->{coat}{lsd} = $player->{coat}{lsd} + $amount;
				$player->{wanted}++;
				print "you purchased $amount $drug\n";
			}
		}
		elsif ( $drug eq "shrooms")
		{
			my $cost = $amount * $shrooms;
			if ($player->{mycash} < $cost)
			{
				print "You lack the funds to buy $amount $drug\n";
			}
			else
			{
				$player->{mycash} = $player->{mycash} - $cost;
				$player->{coat}{shrooms} = $player->{coat}{shrooms} + $amount;
				$player->{wanted}++;
				print "you purchased $amount $drug\n";
			}
		}
		elsif ( $drug eq "skooma")
		{
			my $cost = $amount * $skooma;
			if ($player->{mycash} < $cost)
			{
				print "You lack the funds to buy $amount $drug\n";
			}
			else
			{
				$player->{mycash} = $player->{mycash} - $cost;
				$player->{coat}{skooma} = $player->{coat}{skooma} + $amount;
				$player->{wanted}++;
				print "you purchased $amount $drug\n";
			}
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


main ();
