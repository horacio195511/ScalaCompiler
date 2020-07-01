/*
 * class: test9, string constant, and or condition
 */

object test9{
    def andor(a:int):int{
        var b:boolean = true
        var c:boolean = true
        var d:int = 0
        if(b || c){
            d = a+1
        }
        return d
    }
    def andor2(a:int, b:int):int{
        var c:int
        if(a-b>10 || a+b>25){
            c = a+b
        }
        return c
    }
    def main(){
        val firstStr:string = "Hello "
        val secondStr = "World "
        val thirdStr:string = "this world suck"
        var a:int
        var b:int
        print(firstStr)
        print(secondStr)
        println(thirdStr)
        a = andor(4)
        println(a)
        b = andor2(25, 15)
        println(b)
    }
}