package utils;

@:forward
abstract SemanticVersion(String) from String to String {
    public var major(get, never):Int;
    public var minor(get, never):Int;
    public var patch(get, never):Int;

    // getters & setters
    @:noCompletion
    private function get_major():Int {
        return Std.parseInt(this.split(".")[0]);
    }

    @:noCompletion
    private function get_minor():Int {
        return Std.parseInt(this.split(".")[1]);
    }

    @:noCompletion
    private function get_patch():Int {
        return Std.parseInt(this.split(".")[2]);
    }

    // operators
    @:noCompletion
    @:op(A > B)
    private function greaterThanOp(a:SemanticVersion):Bool {
        return (major > a.major) || (minor > a.minor) || (patch > a.patch);
    }

    @:noCompletion
    @:op(A >= B)
    private function greaterThanEqualOp(a:SemanticVersion):Bool {
        return (major >= a.major) || (minor >= a.minor) || (patch >= a.patch);
    }

    @:noCompletion
    @:op(A < B)
    private function lessThanOp(a:SemanticVersion):Bool {
        return (major < a.major) || (minor < a.minor) || (patch < a.patch);
    }

    @:noCompletion
    @:op(A <= B)
    private function lessThanEqualOp(a:SemanticVersion):Bool {
        return (major <= a.major) || (minor <= a.minor) || (patch <= a.patch);
    }
}