/*
 * class: test1, two functions
 */

object test1{
    //empty string
    val str1:string=""
    def add(a:int, b:int):int{
        var result:int
        result = a+b
        return result
    }
    def mul(a:int, b:int):int{
        var result:int
        println (a*b)
        result = a+b
        return result
    }
    def main(){
        var pi:int = 5
        var c:int
        c= mul(5,5)
        pi = add(5, 3)
        println(c)
        println(pi)
    }
}