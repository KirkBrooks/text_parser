//%attributes = {"shared":true}
  //  __test
  // Written by: Kirk as Designer, Created: 04/15/18, 09:46:37
  // ------------------
  // Method: __test ()
  // Purpose: 

C_LONGINT:C283($i;$n)
C_TEXT:C284($errMsg;$text;$path)
C_OBJECT:C1216($obj;$resObj;$file_o)
C_BOOLEAN:C305($ok)
C_LONGINT:C283($ms)
Progress QUIT (0)
C_COLLECTION:C1488($records_c)


  // -- [non-standard CSV import]
If (False:C215)
	$path:=Folder:C1567(fk resources folder:K87:11).platformPath+"test1.csv"
	$file_o:=File:C1566($path;fk platform path:K87:2)
	$text:=$file_o.getText()
	$records_c:=Text_parser (->$text;New object:C1471("field_delim";",";"rec_delim";"\r";"dblQtEscaped";False:C215))
	
End if 

  // --  [ nice, large CSV file ]
If (True:C214)
	
	$ms:=Milliseconds:C459
	
	
	$path:=Folder:C1567(fk resources folder:K87:11).platformPath+"lhp_items.csv"
	$file_o:=File:C1566($path;fk platform path:K87:2)
	$text:=$file_o.getText()
	$records_c:=Text_parser (->$text)
	
	$ms:=Milliseconds:C459-$ms
	ALERT:C41("This run: "+String:C10($ms))
	
End if 


