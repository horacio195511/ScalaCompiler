/*
 * class: test5, nested while loop
 */

 object test5{
     def onewhile(a:int):int{
         var j:int = 0
         var temp:int = 0
         while(j <= a){
             temp = temp + j
             j = j+1
         }
         return temp
     }
     def twowhile(a:int, b:int):int{
         var i:int = 0
         var j:int = 0
         var temp = 0
         while(i <= a){
             while(j <= b){
                 temp = temp + j
                 j = j+1
             }
             j=0
             i = i+1
         }
         return temp
     }
     def threewhile(a:int, b:int, c:int):int{
         var i:int = 0
         var j:int = 0
         var k:int = 0
         var temp:int = 0
         while(i <= a){
             while(j <= b){
                 while(k <= c){
                     temp = temp + k
                     k = k+1
                 }
                 j = j+1
                 k=0
             }
             i = i+1
             j=0
         }
         return temp
     }
     def main(){
         var a:int
         var b:int
         var c:int
         a = onewhile(10)
         b = twowhile(10, 10)
         c = threewhile(10, 10, 10)
         println(a)
         println(b)
         println(c)
     }
 }