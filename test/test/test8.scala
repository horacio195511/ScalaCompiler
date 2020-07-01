/*
 * class: test8, read implementation test.
 * read a int and pass to a procedure
 * read a string and print it on monitor
 * and string constant
 */

 object test8{
     def add(a:int, b:int):int{
         return a+b
     }
     
     def main(){
         var a:int = 0
         var b:int = 0
         val str1:string = "Enter first integer to add:"
         val str2:string = "Enter second integer to add:"
         print(str1)
         read a
         print(str2)
         read b
         println(add(a,b))
     }
 }