/*
 * class: test4, nested if...else... statement and while loop
 */

object test4{
    val real:int = 10
    def fib(a:int):int{
        var i0=1
        var i1=1
        var i2=2
        var temp=0
        var j=2
        if(a == 0){
            temp = i0
        }else{
            if(a == 1){
                temp = i1
            }else{
                if(a == 2){
                    temp = i2
                }else{
                    while(j < a){
                        i0 = i1
                        i1 = i2
                        i2 = i1+i0
                        j=j+1
                        temp = i2
                    }
                }
            }
        }
        return temp
    }
    def main(){
        var c:int
        var d:int
        print("fib of ")
        read d
        c = fib(d)
        print(" = ")
        println(c)
    }
}