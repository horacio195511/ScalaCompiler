/*
 * class: test6, nested for loop
 */

 object test6{
     def onefor(a:int):int{
         var b:int = 0
         var c:int = 0
         for(b <- 5 to 10){
             c = c+a
         }
         return c
     }

     def twofor(a:int, b:int):int{
         var d:int
         var e:int
         var f:int
         for(d <- 5 to 10){
             for(e <- 5 to 10){
                 f = f+a
             }
             f = f+b
         }
         return f
     }

     def threefor(a:int, b:int, c:int):int{
         var d:int
         var e:int
         var f:int
         var g:int
         for(d <- 5 to 10){
             for(e <- 5 to 10){
                 for(f <- 5 to 10){
                     g = g+a
                 }
                 g = g+b
             }
             g = g+c
         }
         return g
     }

     def main(){
         var a: int = 3
         var b: int = 2
         var c: int = 5
         a = onefor(a)
         b = twofor(a, b)
         c = threefor(a, b, c)
         print("a = ")
         println(a)
         print("b = ")
         println(b)
         print("c = ")
         println(c)
     }
 }