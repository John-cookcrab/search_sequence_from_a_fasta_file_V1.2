#!usr/bin/perl
use utf8;
binmode(STDOUT, ":encoding(gbk)");
sub help {
    print "
##############
写一个所要查找的序列名字的列表，不要有空行，名字以回车键换行
若在序列名字后添加制表符数字：数字，则会根据序列的位置进行序列截取 eg:CCG057411.1	20:80
以:perl search_sequence_from_a_fasta_file.pl [序列文件] [列表文件] 进行运行，运行结果出现在列表文件文件夹中
##############
"
}
if ( grep {$_ eq "-h"} @ARGV ) {
    help();
    exit;
}
open FILE, '<', $ARGV[0] or die "We can't open the sequence file : $!";
@raw_lines = readline FILE;
close FILE;
my @lines;
foreach (@raw_lines) {
    chomp;
    push @lines, $_;
}#将文件中的每一行读取并去掉回车键，然后加入@lines
undef @raw_lines;
$num = $#lines;
my %seq_dir;
foreach $i (0..$num) {
    if ($lines[$i] =~ /^>/){
        my $name = $lines[$i] ;
        $i++;
        my $seq;
        until ($lines[$i] =~ /^>/ || $i == $num+1 ) {
            $seq .= $lines[$i];
            $i++;
        }
        $seq_dir{$name} = $seq; 
    }
}#将带有>的行作为哈希的key，非>的行连接为序列作为哈希的value，构成哈希%seq_dir
undef @lines;
my $dir_list;
foreach $key (sort keys %seq_dir) {
    $dir_list .= $key."\n";
}#将%seq_dir中的key连接成为dir_list

open ASKSEQ, '<', $ARGV[1] or die "We can't open the ask file : $!";
open OUT1, '>', $ARGV[1]."_out.fasta" or die "We can't create the output file : $!";
open OUT2, '>', $ARGV[1]."_out.log" or die "We can't create the output file : $!";
while (<ASKSEQ>) {
    chomp;
    my ($askname, $split_num) = (split "\t", $_)[0,-1];
    unless ($dir_list =~ /$askname/i) {
        print OUT2 "$_ isn't found!!!\n";
    }#在key列表中寻找是否有目的序列名称，没有的话在log文件中输出
    foreach $key (sort keys %seq_dir) {
        if ($key =~ /$askname/i){
            print "$key\n";
            print OUT2 "$_ is found!!!\n";
            if ($split_num =~ /^\d*:\d*$/ ) { #检测是否输入了截取区域，如输入了区域针对区域截取
                my($start_num, $stop_num) = split ":", $split_num;
                $start_num -= 1;
                my $length = $stop_num - $start_num;
                unless(my $seq = substr $seq_dir{$key}, $start_num, $length) {
                    print OUT2 "But inputed range is out of sequence range\n"; #检测是否有截取，没截取的话将提示输入有区域有误
                }else{
                    if (length $seq == $length) {
                        print OUT1 "$key\t$split_num\n$seq\n";
                    }else {
                        print OUT2 "But the inputed range is out of sequence range\n"; #检测截取的长度是否正确，长度不正确的话将提示输入有区域有误
                    }
                }
            }else{
                print OUT1 "$key\n$seq_dir{$key}\n";
            }
		}
	}#在key列表中有序列名称的输出序列，并在log文件中记录找到的序列名字
}
close ASKSEQ,OUT1,OUT2;
print "Finished!!!\n";