//%attributes = {}
  //  Text_parser_const ()
  // $1: ptr to text
  // $2: field delim str
  // $3: record delim str
  // $4: FALSE when double quotes inside a quoted field are not escaped with a double quote
  // Written by: Kirk as Designer, Created: 12/29/19, 10:54:12
  // ------------------
  // Purpose: handle text parsing
  // Works with CSV by default. 
  // Field and record delim may be up to 3 chracters long. 
  // The field delim may be omitted. This is useful for parsing paragraphs, for example. 
  // Or the field delim may be ". " to parse sentences in the paragraphs. 
  // re $4:  the default (TRUE) is the standard. eg. 
  //  correct:   "The length is 12"""
  //  incorrect: "The length is 12""
  //  acceptable: "The length is 12\""

C_OBJECT:C1216($0)
C_TEXT:C284($1;$2;$3)
C_BOOLEAN:C305($4)
C_OBJECT:C1216($obj)
C_LONGINT:C283($i;$indx)
C_COLLECTION:C1488($lex)
C_BOOLEAN:C305($br)

If (False:C215)
	C_OBJECT:C1216(Text_parser_const ;$0)
	C_TEXT:C284(Text_parser_const ;$1)
	C_TEXT:C284(Text_parser_const ;$2)
	C_TEXT:C284(Text_parser_const ;$3)
	C_BOOLEAN:C305(Text_parser_const ;$4)
End if 

If (This:C1470[""]=Null:C1517)  //  constructor
	
	Case of 
		: (Not:C34(Asserted:C1132(Length:C16($1)>5;"There is no data to parse.")))
		: (Not:C34(Asserted:C1132(Length:C16($2)<=3;"The field delim string can not be longer than 3 characters.")))
		: (Not:C34(Asserted:C1132(Length:C16($3)<=3;"The record delim string can not be longer than 3 characters.")))
		: (Not:C34(Asserted:C1132(Length:C16($3)#0;"The record delim string can not be Empty.")))
			  // but the field delim can
		Else 
			$obj:=New object:C1471
			$obj[""]:=Current method name:C684
			
			$obj.lex:=New collection:C1472("";"";$1[[1]];$1[[2]];$1[[3]])
			
			$obj.field_delim:=Split string:C1554($2;"")
			$obj.rec_delim:=Split string:C1554($3;"")
			$obj.rec_br:=0
			$obj.field_br:=0
			
			  //  when this is TRUE it means double quotes (") will be escaped with another double quote
			  //  FALSE means the double quotes are just passed through if the field is already quoted
			If (Count parameters:C259>3)
				$obj.dblQtEscaped:=$4
			Else   //   go with the standard 
				$obj.dblQtEscaped:=True:C214
			End if 
			
			$obj.inQt:=False:C215
			$obj.inValue:=False:C215  //  true when parsing into a field 
			$obj.skip:=0  // number of chars to skip
			
			$obj.action:=""
			$obj.value:=""
			
			  // METHODS
			$obj.push:=Formula:C1597(Text_parser_const ("push";$1))
			
	End case 
	
	$0:=$obj
	
Else 
	
	$obj:=This:C1470
	
	Case of 
		: ($1="push")
			$lex:=$obj.lex
			
			$lex.shift()  // remove first char
			$lex.push($2)
			
			$obj.action:=""
			$obj.value:=""
			  // is there a break coming?
			  // --------------------------------------------------------
			
			$indx:=$lex.indexOf($obj.rec_delim[0];1)
			
			If ($indx>-1) & (($indx+$obj.rec_delim.length)<=($lex.length))
				$br:=True:C214
				For ($i;$indx;$obj.rec_delim.length)
					$br:=$br & ($lex[$i]=$obj.rec_delim[$i-1])
				End for 
			Else 
				$br:=False:C215
			End if 
			
			If ($br)
				$obj.rec_br:=$indx
			Else 
				$obj.rec_br:=0
			End if 
			
			  // --------------------------------------------------------
			If ($obj.field_delim.length>0)
				$indx:=$lex.indexOf($obj.field_delim[0];1)
				
				If ($indx>-1) & (($indx+$obj.field_delim.length)<=($lex.length))
					$br:=True:C214
					For ($i;$indx;$obj.field_delim.length)
						$br:=$br & ($lex[$i]=$obj.field_delim[$i-1])
					End for 
				Else 
					$br:=False:C215
				End if 
				
				If ($br)
					$obj.field_br:=$indx
				Else 
					$obj.field_br:=0
				End if 
			End if 
			  // --------------------------------------------------------
			  // we are evaluating $lex[1]
			  // NOTE: **  the order of these statements is critical **
			Case of 
				: ($obj.skip>0)  //  like when the delimiter string is longer than 1
					$obj.skip:=$obj.skip-1
					$obj.action:="skip"
				: ($lex[1]=Char:C90(Escape:K15:39))  // next char is escaped
					$obj.action:="skip"
					$lex[1]:="esc"
					
				: ($lex[0]="esc")  // this char is escaped
					$obj.action:="save"
					$obj.inValue:=True:C214
					$obj.value:=$lex[1]
					
				: ($lex[1]=Char:C90(Double quote:K15:41)) & ($obj.inValue=False:C215)  // start of new quoted field
					$obj.action:="skip"
					$obj.inValue:=True:C214
					$obj.inQt:=True:C214
					$lex[1]:="||"
					
				: ($lex[1]=Char:C90(Double quote:K15:41)) & ($obj.inQt)  // we are in a quoted block & encounter a double quote
					  // this is either the end of the quoted block or a pair of double quotes
					Case of 
						: ($lex[0]="++")  // this is an escaped double quote
							$obj.action:="save"
							$obj.value:=$lex[1]
							
						: ($lex[2]=Char:C90(Double quote:K15:41)) & ($obj.dblQtEscaped)  // start of a double quote
							$obj.action:="skip"
							$lex[1]:="++"
							$obj.value:=""
							
						: ($obj.field_br=2) | ($obj.rec_br=2)  // there is a break following - end of the field
							$obj.action:="skip"
							$obj.inQt:=False:C215
							$obj.value:=""
							
						Else   //  print it
							$obj.action:="save"
							$obj.value:=$lex[1]
					End case 
					
				: ($obj.field_br=1) & (Not:C34($obj.inQt))  //  field break
					$obj.action:="field break"
					$obj.inValue:=False:C215
					$obj.value:=""
					$obj.skip:=$obj.field_delim.length-1
					
				: ($obj.rec_br=1) & (Not:C34($obj.inQt))  //  record break
					$obj.action:="record break"
					$obj.inValue:=False:C215
					$obj.skip:=$obj.rec_delim.length-1
					
				Else   //   just a character to save
					$obj.inValue:=True:C214
					$obj.action:="save"
					$obj.value:=$lex[1]
			End case 
			
	End case 
	
End if 

