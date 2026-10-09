.pragma library

// The launcher's calculator, like typing "12*3" into the Windows Start menu.
// A small recursive-descent parser (no eval): numbers, + - * / ^, × ÷, brackets.
//
//   expr   := term (("+" | "-") term)*
//   term   := power (("*" | "/") power)*
//   power  := unary ("^" power)?
//   unary  := ("+" | "-") unary | number | "(" expr ")"

function tokens(text) {
    var out = [];
    var s = text.replace(/×/g, "*").replace(/÷/g, "/").replace(/\s+/g, "");
    var i = 0;
    while (i < s.length) {
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

// The value of a math expression, or null when the text isn't one (a plain number
// isn't either: there is nothing to work out)
function evaluate(text) {
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
        var value = power();
        while (peek() === "*" || peek() === "/") {
            var op = list[pos++];
            var right = power();
            value = op === "*" ? value * right : value / right;
        }
        return value;
    }

    function power() {
        var base = unary();
        if (peek() === "^") {
            pos++;
            return Math.pow(base, power());
        }
        return base;
    }

    function unary() {
        var t = list[pos++];
        if (t === "-")
            return -unary();
        if (t === "+")
            return unary();
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
