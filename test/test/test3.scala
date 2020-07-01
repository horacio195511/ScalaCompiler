/*
 * class: test3 example code given by course
 */

object test3{
    val pi:int = 3
    var a = 3
    def power(a:int, b:int):int{
        var i=0
        var j=1
        i = a
        while(j<b){
            i=i*a
            j=j+1
        }
        return i
    }
    def main(){
        var a:int = 0
        a=power(2,3)
        println(a)
    }
}