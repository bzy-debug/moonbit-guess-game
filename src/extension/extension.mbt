///|
priv enum Color {
  R
  G
  B
} derive(Show)

///|
async fn activate_(context : @vscode.ExtensionContext) -> Unit {
  let subscriptions = context.get_subscriptions()
  let colos : Array[Color] = [R, G, B]
  subscriptions.push(
    @vscode.Commands::register_command("answer", fn(_args) { 42 }),
  )
  subscriptions.push(
    @vscode.Commands::register_command("id", fn(args) { args }),
  )
  subscriptions.push(
    @vscode.Commands::register_command("moonbit-guess-number.start", fn(_args) {
      let answer : Int = @vscode.Commands::execute_command!!("answer", [])
      let colors : Array[Color] = @vscode.Commands::execute_command!!(
        "id",
        colos.map(@js.Value::cast_from),
      )
      @vscode.Window::show_information_message!!("Hello \{answer} \{colors}")
    }),
  )
  @js.Promise::new(fn() {
    @vscode.Window::show_information_message!!("Hello", items=["1"])
  }).dont_wait()
  println("not wait")
}

///|
pub fn activate(context : @vscode.ExtensionContext) -> Unit {
  @js.Promise::new(fn() { activate_!!(context) }) |> ignore
}

///|
pub fn deactivate() -> Unit {
  println("goodbye")
}
