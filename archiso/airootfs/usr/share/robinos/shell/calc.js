.pragma library

// The launcher's calculator, like typing "12*3" into the Windows Start menu.
// A small recursive-descent parser (no eval): numbers, + - * / ^, × ÷, brackets.
// A sign binds looser than ^, as in maths: -2^2 is -4.
//
//   expr   := term (("+" | "-") term)*
//   term   := unary (("*" | "/") unary)*
//   unary  := ("+" | "-") unary | power
//   power  := primary ("^" unary)?
//   primary := number | "(" expr ")"

function tokens(text) {
    var out = [];
    var s = text.replace(/×/g, "*").replace(/÷/g, "/");
    var i = 0;
    while (i < s.length) {
        // Spaces only separate: "1 2+3" is two numbers side by side, not 12+3
        if (/\s/.test(s[i])) {
            i++;
            continue;
        }
        var m = /^(\d+(\.\d*)?|\.\d+)/.exec(s.slice(i));
        if (m) {
            out.push(parseFloat(m[0]));
            i += m[0].length;
        } else if ("+-*/^()".indexOf(s[i]) !== -1) {
            out.push(s[i]);
            i++;
        } else {
            return null;
        }
    }
    return out;
}

// The value of a math expression, or null when the text isn't one: a plain number,
// or a date or phone number like 2026-10-10 and 010-1234-5678 (people search for
// those, so the launcher keeps them for files)
function evaluate(text) {
    if (/^\s*\d{2,}(-\d{2,}){2,}\s*$/.test(text))
        return null;
    var list = tokens(text);
    if (!list || list.length < 3 || !list.some(function (t) { return typeof t === "string" && t !== "(" && t !== ")"; }))
        return null;
    var pos = 0;

    function peek() {
        return list[pos];
    }

    function expr() {
        var value = term();
        while (peek() === "+" || peek() === "-") {
            var op = list[pos++];
            var right = term();
            value = op === "+" ? value + right : value - right;
        }
        return value;
    }

    function term() {
        var value = unary();
        while (peek() === "*" || peek() === "/") {
            var op = list[pos++];
            var right = unary();
            value = op === "*" ? value * right : value / right;
        }
        return value;
    }

    function unary() {
        if (peek() === "-") {
            pos++;
            return -unary();
        }
        if (peek() === "+") {
            pos++;
            return unary();
        }
        return power();
    }

    function power() {
        var base = primary();
        if (peek() === "^") {
            pos++;
            return Math.pow(base, unary());
        }
        return base;
    }

    function primary() {
        var t = list[pos++];
        if (typeof t === "number")
            return t;
        if (t === "(") {
            var value = expr();
            if (list[pos++] !== ")")
                throw new Error("bracket");
            return value;
        }
        throw new Error("syntax");
    }

    try {
        var result = expr();
        return pos === list.length && isFinite(result) ? result : null;
    } catch (e) {
        return null;
    }
}

// 12 significant digits, so 0.1+0.2 shows 0.3
function format(value) {
    return String(parseFloat(value.toPrecision(12)));
}
