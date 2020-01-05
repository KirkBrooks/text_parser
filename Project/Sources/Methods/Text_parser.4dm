//%attributes = {}
  //  Text_parser (pointer; object) -> collection
  // $1: ptr to text
  // $2: params: {  }
  // $0: collection of parsed elements
  // Written by: Kirk as Designer, Created: 12/29/19, 09:55:29
  // ------------------
  // Purpose: parse the text into fields and records. 
  // $0 will be a collection where each element is a record
  //    each record will be a collection where each element is a field. 
  //    If the field delim is "" the text is parsed to records (paragraphs actually)
  // $2 contains field & record delimiters. These are strings
  // defaults are comma and CR.
  // In CSV double quotes within the quoted line are typically indicated by "".
  // eg. "length 14""" 
  // We consider any escaped chars to be the trailing char. 
  // Once a quoted line is begun it is only ended with a double quote followed by a delim. 


C_POINTER:C301($1)
C_OBJECT:C1216($2)
C_COLLECTION:C1488($0;$records_c;$fields_c)
C_TEXT:C284($text;$field_delim;$rec_delim;$value_t)
C_BOOLEAN:C305($ignore_rempty_rec;$dblQtEscaped)
C_LONGINT:C283($n_chars;$action;$i)
C_OBJECT:C1216($obj)

  // normalize the Cr/Lfs
$text:=Replace string:C233($1->;"\r\n";"\r")  // replace CrLf
$text:=Replace string:C233($text;"\n";"\r")  //  replace Lf
$n_chars:=Length:C16($text)

$rec_delim:=Char:C90(Carriage return:K15:38)
$field_delim:=","
$dblQtEscaped:=True:C214  //  this is the correct way 
$ignore_rempty_rec:=True:C214

If (Count parameters:C259>1)
	
	If ($2.field_delim#Null:C1517)
		$field_delim:=$2.field_delim
	End if 
	
	If ($2.rec_delim#Null:C1517)
		$rec_delim:=$2.rec_delim
	End if 
	
	$dblQtEscaped:=OB Get:C1224($2;"dblQtEscaped";Is boolean:K8:9)
	
End if 

If (Asserted:C1132($n_chars>5;"No data to parse."))
	
	$obj:=Text_parser_const ($text;$field_delim;$rec_delim;$dblQtEscaped)
	
	$records_c:=New collection:C1472
	$fields_c:=New collection:C1472
	$value_t:=""
	
	  // --------------------------------------------------------
	C_LONGINT:C283($progress_id)
	$progress_id:=Progress New 
	Progress SET TITLE ($progress_id;"Parsing text...";-1)
	  // --------------------------------------------------------
	
	  //  loop through each character
	For ($i;1;$n_chars)
		If ($i%100=0)
			Progress SET PROGRESS ($progress_id;$i/$n_chars)
		End if 
		
		If ($i+3<$n_chars)
			$obj.push($text[[$i+3]])
		Else   // near the end
			$obj.push("\r")
		End if 
		  // --------------------------------------------------------
		
		Case of 
			: ($obj.action="skip")  // igonore this char
				
			: ($obj.action="save")  //  concat to current value
				$value_t:=$value_t+$obj.value
				
			: ($obj.action="field break")  //  end of a field
				$fields_c.push($value_t)
				$value_t:=""
				
			: ($obj.action="record break")  //  end of a record
				$fields_c.push($value_t)
				$value_t:=""
				$records_c.push($fields_c)
				$fields_c:=New collection:C1472
		End case 
		
	End for 
	
	  // --------------------------------------------------------
	Progress QUIT ($progress_id)
	  // --------------------------------------------------------
End if 

If ($fields_c.length>0)
	$records_c.push($fields_c)
End if 

$0:=$records_c
