# Albÿno OS

This is the home of my OS for ComputerCraft.

  - working "apt-get" with addable repos (the repos have a simple format)
  - file explorer based on FileX
  - very basic KDE-like desktop (think Windows)
  - configurable default programs
  - programs can register formats that they can open
  - a bunch of shell jargon that most people don't care about
  - basic multi-user login system
  - basic filesystem protection
  - auto-update (configurable)

## Installation

replace &lt;disk/startup&gt; with whatever location you want, but is needs to be on a disk.<br>
<br>
You can either download
from [github](https://raw.githubusercontent.com/EtK2000/Alb-no-OS/master/installer) (the most recent version):
### wget https://raw.githubusercontent.com/EtK2000/Alb-no-OS/master/installer &lt;disk/startup&gt;<br>
or from [my site](http://cc.etk2000.com/albÿno/src/installer) (the most recent stable version):
### wget http://cc.etk2000.com/alb%C3%BFno/src/installer &lt;disk/startup&gt;

Now just run &lt;disk/startup&gt;.

## Repo setup

Any line starting with '#' will be ignored.<br>
<br>
[basepath] is the url to hit for installing modules, it can contains any of 2 variables:<br>
  $name  - name of the module file (string) [required]<br>
  $ver   - version of the module (number)<br>
An example would be:<br>
[basepath]=http://cc.etk2000.com/albÿno/src/modules/$name<br>
<br>
Format of lines, available variables are:<br>
$alone - is the module standalone? (0/1) [defaults to 1]<br>
$dep   - modules the module depends on (string) [format: &lt;dep 1&gt;;&lt;dep 2&gt;;&lt;dep 3&gt;]<br>
$disp  - display name of the module (string) [defaults to $name]<br>
$name  - name of the module file (string)<br>
$max   - the maximum Albÿno version (number &gt;= $min) [normally build version, defaults to infinity]<br>
$min   - the minimum Albÿno version required (number &gt;= 0) [defaults to 0]<br>
$req   - is the module required by the source? (0/1) [defaults to 0]<br>
$run   - the url of the file to be run at startup for this module [defaults to nil]<br>
$ver   - version of the module (number &gt; 0)<br>
<br>
Not all vars have to be filled in, but $name and $ver are required<br>
Here is an example:<br>
[format]=$name,$ver,$req,$dep,$min,$max<br>
apt-get,0.2,1<br>
<br>
[See this example in action](http://cc.etk2000.com/alb%C3%BFno/modules).
