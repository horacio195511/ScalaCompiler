/*
 * class: test10, array utility
 * a fibonacci based on dynamic programming
 */

object test10{
    def fib(a:int):int{
        var i:int = 2
        var temp:int= 1
        var fibarray:int [ 20 ]
        /* although this algorithm is capable of fast
         * fibonacci sequence, but we won't use that much.
         */
        fibarray[ 0 ] = 1
        fibarray[ 1 ] = 1
        if(a == 0){
            temp = fibarray[0]
        }else{
            if(a == 1){
                temp = fibarray[1]
            }else{
                while(i <= a){
                    fibarray[i] = fibarray[i-1] + fibarray[i-2]
                    temp = fibarray[i]
                    i = i+1
                }
            }
        }
        return temp
    }
    def main(){
        var a:int
        print("fib of ")
        read a
        a = fib(a)
        println(a)
    }
}