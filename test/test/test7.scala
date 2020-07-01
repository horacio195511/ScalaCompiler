/*
 * conditional, while, for all together
 */

object test7{
    def twoinone(a:int, b:int):int{
        var c:int
        var d:int=0
        for(c <- 5 to 10){
            while(c*b < 20){
                d = d+a
            }
        }
        return d
    }
    
    def threeinone(a:int, b:int):int{
        var c:int
        var d:int=1
        for(c <- 5 to 10){
            while(c*b < 20){
                if(c*d <15){
                    d = a+d
                }else{
                    d = b+d
                }
            }
        }
        return d
    }

    def main(){
        var c:int
        var d:int
        c = twoinone(10, 10)
        d = threeinone(10, 10)
        println(c)
        println(d)
    }
}