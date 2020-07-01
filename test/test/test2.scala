/*
 *  test2: Example with Functions
 */

 object test2{
     // constants
     val a = 5

     // variables
     var c:int

     // function declaration
     def add(a:int, b:int):int{
         var c :int
         c = a+b
         return c
     }

     //main statement
     def main(){
         c = add(a, 10)
         if(c > 10)
            print(-c)
        else
            print(c)
        println("Hello World")
     }
 }