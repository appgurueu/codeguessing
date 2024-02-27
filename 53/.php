#!/c/Program\ Files/PHP/php.exe
<?php
ini_set('evil_bit', 1);
$a=[];
while ($b=rtrim(fgets(STDIN), "\n\r"))
	{ $cs=array();
	  preg_match_all('/./u',$b,$cs);
	  $a[]=$cs[0];
	}
function d() {
global $a;
foreach ($a as $r)
{
	foreach ($r as $c)
		echo $c;
	echo "\n";
}
}
function ass($c) {
	if ($c) {
		return;
	}
	echo "invalid!!!";
	exit(69);
}
class RectAngle
{
	public readonly int $x1, $x2, $y1, $y2;
	public function __construct($x1, $x2, $y1, $y2) {
		$this->x1 = $x1;
		$this->x2 = $x2;
		$this->y1 = $y1;
		$this->y2 = $y2;
    }
    public function loop($f) {
		for ($x = $this->x1; $x <= $this->x2; $x++)
			for ($y = $this->y1; $y <= $this->y2; $y++)
				$f($x,$y);
    }
    public function cr() {
    	global $a;
    	$a[$this->y1][$this->x1]=$a[$this->y1][$this->x2]=$a[$this->y2][$this->x1]=$a[$this->y2][$this->x2]=' ';
    }
    public function inp($x,$y) {
    	return $x >= $this->x1 && $x <= $this->x2 && $y >= $this->y1 && $y <= $this->y2;
    }
}
if (!($h=count($a))) {
	exit;
}
$w=count($a[0]);
$rn=0;
$ls=[
	'│' => "UD",
	'─' => "LR",
	'┴' => "LRU",
	'┬' => "LRD",
	'┤' => "LUD",
	'├' => "RUD",
	'┌' => "DR",
	'┐' => "LD",
	'└' => "UR",
	'┘' => "LU",
];
$ds=[
	"L" => [-1,0],
	"R" => [1,0],
	"U" => [0,-1],
	"D" => [0,1],
];
$br=[];
foreach ($a as $y=>$r) {
	foreach ($r as $x=>$c) {
		switch ($c) {
			case '┌':
				$xn = $x;
				while (++$xn < $w && $r[$xn] != '┐');
				if ($xn==$w) continue 2;
				$yn = $y;
				while (++$yn < $h && $a[$yn][$x] != '└');
				if ($yn==$h) continue 2;
				if ($a[$yn][$xn] != '┘') continue 2;
				$re=new RectAngle($x,$xn,$y,$yn);
				$re->cr();
				$con=[++$rn=>true];
				$fl = function($x,$y) use ($re,&$br,$rn,$ds,$ls,$w,$h,&$con) {
					global $a;
					$br[$y][$x] = $rn;
					$in=0;
					$dv=null;
					ass(array_key_exists($a[$y][$x],$ls));
					foreach (str_split($ls[$a[$y][$x]]) as $dc) {
						$dw=$ds[$dc];$xm=$x+$dw[0];$ym=$y+$dw[1];
						if ($re->inp($xm,$ym)) $in++;
						else $dv = $dw;
					}
					ass($in==2);
					$a[$y][$x]=' ';
					if ($dv==null) return;
					$kill=[];
					while (1) {
						$x+=$dv[0];$y+=$dv[1];
						$kill[]=[$x,$y];
						ass((new RectAngle(0,$w-1,0,$h-1))->inp($x,$y));
						$re2 = null;
						if (array_key_exists($y,$br) && array_key_exists($x,$br[$y]))
							$re2 = $br[$y][$x];
						if ($re2!=null) {
							ass(!array_key_exists($re2,$con));
							$con[$re2]=true;
							foreach ($kill as $k)
								$a[$k[1]][$k[0]]=' ';
							break;
						}
						ass(array_key_exists($a[$y][$x],$ls));
						$sl = strlen($ls[$a[$y][$x]]);
						if ($sl==3) break;
						ass($sl==2);
						$dv2=null;
						foreach (str_split($ls[$a[$y][$x]]) as $dc) {
							$dvc=$ds[$dc];
							if ($dvc[0]!=-$dv[0] || $dvc[1]!=-$dv[1])
								$dv2=$dvc; #there is no going back
						}
						$dv=$dv2;
					}
				};
				(new RectAngle($x+1, $xn-1, $y+1, $yn-1))->loop(function($x,$y) {
					 global $a;
					ass($a[$y][$x] == ' ');
				});
				foreach ([
					new RectAngle($x+1, $xn-1, $y, $y),
					new RectAngle($x+1, $xn-1, $yn, $yn),
					new RectAngle($x, $x, $y+1, $yn-1),
					new RectAngle($xn, $xn, $y+1, $yn-1)
				] as $rl) $rl->loop($fl);
				break;
			case '│':
			case '─':
			case '┴':
			case '┬':
			case '┤':
			case '├':
			case '┐':
			case '└':
			case '┘':
			case ' ':
				break; # a ok
			default:
				ass(0);
		}
	}
}
foreach ($a as $r)
	foreach ($r as $c)
		ass($c==' ');
?>
