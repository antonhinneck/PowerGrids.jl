Attribute VB_Name = "Utils"
Sub del_semicolons()

Dim last_row As Integer
Dim column As Integer
Dim current_cell_value As String
Dim current_cell_length As Integer

column = CInt(InputBox("InputColumnNumber"))
last_row = Cells(Rows.Count, 1).End(xlUp).Row
current_cell_value = ""

 For i = 2 To last_row
 
    current_cell_value = ActiveSheet.Cells(i, column).Value
    current_cell_length = Len(current_cell_value)
    
    For j = 1 To Len(current_cell_value)
    
        If Mid(current_cell_value, j, 1) = ";" Then
        
            ActiveSheet.Cells(i, column).Value = CDbl(Left(current_cell_value, j - 1))
            Exit For
            
        End If
    Next j
 Next i

End Sub
