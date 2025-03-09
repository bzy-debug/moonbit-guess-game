///|
priv enum State {
  Start
  Guess(guess~ : Int, tries~ : Int)
  Success(tries~ : Int)
  Fail
  Exit
}

///|
let bytes : Ref[Bytes] = Ref::new(b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")

///|
fn seed() -> Bytes {
  let rand = @random.new(seed=bytes.val)
  let byte = rand.int().to_byte()
  bytes.val = @bytes.from_array([byte].repeat(32))
  bytes.val
}

///|
async fn start_game() -> Unit! {
  let rand = @random.new(seed=seed())
  let answer = rand.int(limit=101)
  let validate_input = fn(input) {
    try {
      @strconv.parse_int!(input, base=10) |> ignore
      None
    } catch {
      _ => Some("\"\{input}\" is not a valid number")
    }
  }
  async fn loop_(state : State) -> Unit! {
    match state {
      Start => {
        let input = @vscode.Window::show_input_box!!(
          options=@vscode.InputBoxOptions::new(
            title="I've picked a number between 0 and 100, can you guess it in 10 tries?",
            place_holder="What's your guess?",
            validate_input~,
          ),
        )
        match input {
          Some(input) => {
            let guess = @strconv.parse_int!(input, base=10)
            loop_!!(Guess(guess~, tries=1))
          }
          None => loop_!!(Exit)
        }
      }
      Guess(guess~, tries~) =>
        if guess == answer {
          loop_!!(Success(tries~))
        } else if tries == 10 {
          loop_!!(Fail)
        } else {
          let message = if guess < answer { "lower" } else { "higher" }
          let input = @vscode.Window::show_input_box!!(
            options=@vscode.InputBoxOptions::new(
              title="Your last guess is \{guess}, but it's \{message} than the answer",
              place_holder="You have \{10 - tries} tries to go, what's your next guess?",
              validate_input~,
            ),
          )
          match input {
            Some(input) => {
              let guess = @strconv.parse_int!(input, base=10)
              loop_!!(Guess(guess~, tries=tries + 1))
            }
            None => loop_!!(Exit)
          }
        }
      Fail =>
        @js.spawn_detach(fn() {
          @vscode.Window::show_information_message!!(
            "You've run out of tries, the answer is \{answer}",
          )
        })
      Success(tries~) =>
        @js.spawn_detach(fn() {
          @vscode.Window::show_information_message!!(
            "Congratulations! You've guessed the number in \{tries} tries",
          )
        })
      Exit =>
        @js.spawn_detach(fn() {
          @vscode.Window::show_information_message!!("Goodbye!")
        })
    }
  }

  loop_!!(Start)
}

///|
pub fn activate(context : @vscode.ExtensionContext) -> Unit {
  let subscriptions = context.get_subscriptions()
  subscriptions.push(
    @vscode.Commands::register_command("moonbit-guess-number.start", fn(_) {
      start_game!!()
    }),
  )
}

///|
pub fn deactivate() -> Unit {
  println("goodbye")
}
