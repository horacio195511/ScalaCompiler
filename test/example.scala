/*
 * Example with Functions
 */

object example {
  val a = 5

  // function declaration
  def add (a: int, b: int) : int
  {
    return a+b
  }
  
  // main statements
  def main()
  {
    var c:int
    c = 1+2/3
    if (c > 10){
      print (-c)
    }else{
      print (c)
    }
    println ("Hello World")
  }
}
