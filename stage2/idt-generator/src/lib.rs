use proc_macro::TokenStream;

fn parse_range(args: TokenStream) -> (usize, usize) {
    let mut start = 0;
    let mut end = 0;

    for (i, token) in args.into_iter().enumerate() {
        match token {
            x if i == 0 => start = x.to_string().parse().unwrap(),
            x if i == 2 => end = x.to_string().parse().unwrap(),
            _ => ()
        }
    }

    (start, end)
}

fn create_isr_ga(n: usize) -> String {
    format!("global_asm!(\"
                .global _isr_internal_{n}
                _isr_internal_{n}:
                push dword ptr 0
                push dword ptr {n}
                jmp _isr_internal_common_stub
            \");
            extern \"C\" {{
                fn _isr_internal_{n}();
            }}", n = n)
}

fn create_isr_err_ga(n: usize) -> String {
    format!("global_asm!(\"
                .global _isr_internal_{n}
                _isr_internal_{n}:
                push dword ptr {n}
                jmp _isr_internal_common_stub
            \");
            extern \"C\" {{
                fn _isr_internal_{n}();
            }}", n = n)
}

fn create_handlers(start: usize, end: usize) -> String {
    let mut handlers = String::new();
    for i in start..=end {
        handlers.push_str(&create_isr_ga(i));
    }
    handlers
}

fn create_handlers_err(start: usize, end: usize) -> String {
    let mut handlers = String::new();
    for i in start..=end {
        handlers.push_str(&create_isr_err_ga(i));
    }
    handlers
}

fn create_handlers_array(start: usize, end: usize) -> String {
    let mut array = String::new();
    array.push_str("[");
    for i in start..=end {
        array.push_str(&format!("(_isr_internal_{} as u32),", i));
    }
    array.push_str("]");
    array
}

#[proc_macro]
pub fn generate_handlers_array(input: TokenStream) -> TokenStream {
    let (start, end) = parse_range(input);
    let array = create_handlers_array(start, end);

    array.parse().unwrap()
}

#[proc_macro]
pub fn generate_handlers(input: TokenStream) -> TokenStream {
    let (start, end) = parse_range(input);
    let array = create_handlers(start, end);

    array.parse().unwrap()
}

#[proc_macro]
pub fn generate_handlers_err(input: TokenStream) -> TokenStream {
    let (start, end) = parse_range(input);
    let array = create_handlers_err(start, end);

    array.parse().unwrap()
}
