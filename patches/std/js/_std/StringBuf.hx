
#if nodejs
import js.node.util.TextDecoder;
import js.node.util.TextEncoder;
#elseif js
import js.html.TextDecoder;
import js.html.TextEncoder;
#end

import js.lib.Uint8Array;

private enum StringBufExpansionMethod {
    Exponential;
    Linear;
}

// alot here is testing / exploration
@:coreApi class StringBuf {
    private var buffer:Uint8Array;
    private var offset:Int = 0;

    private static inline var ChunkSize = 1024;
    private static inline var ExpansionMethod = Exponential;

    public function new():Void {
        buffer = new Uint8Array(0);
        offset = 0;
    }

	public var length(get, never):Int;
	inline function get_length():Int {
		return this.offset;
	}

    public function add<T>(x:T):Void {
        if (x == null) {
            return;
        }
        if (x is String) {
            addSub(cast x, 0);
        } else if (x is haxe.io.Bytes) {
            var b:haxe.io.Bytes = cast x;
            appendNativeBytes(cast b.getData());
        } else {
            trace(Type.typeof(x));
            throw 'no impl';
        }
    }

    public function addSub(s:String, pos:Int, ?len:Int):Void {
        if (len == null) {
            len = s.length;
        }
        for (i in pos...len) {
            addChar(s.charCodeAt(i));
        }
    }

    public function addChar(c:Int):Void {
        // basic UTF-16 => UTF-8 encoder (gpt)
        if (c < 0x80) {
            this.appendIntArray([c]);
        } else if (c < 0x800) {
            this.appendIntArray([
                0xc0 | (c >> 6),
                0x80 | (c & 0x3f)
            ]);
        } else {
            this.appendIntArray([
                0xe0 | (c >> 12),
                0x80 | ((c >> 6) & 0x3f),
                0x80 | (c & 0x3f)
            ]);
        }
    }

    public function toString():String {
        var decoder = new TextDecoder();
        return decoder.decode(toNativeArray());
    }

    private function appendNativeBytes(bytes:Uint8Array):Void {
        ensureCapacity(bytes.length);
        buffer.set(bytes, offset);
        offset += bytes.length;
    }

    private function appendIntArray(bytes:Array<Int>):Void {
        ensureCapacity(bytes.length);
        buffer.set(bytes, offset);
        offset += bytes.length;
    }

    private function ensureCapacity(additional:Int):Void {
        var required = offset + additional;
        if (required <= buffer.length) {
            return;
        }

        var newSize = this.buffer.length;
        if (ExpansionMethod == Exponential && newSize == 0) {
            newSize = 1;
        }
        while (newSize < required) {
            if (ExpansionMethod == Exponential) {
                newSize *= 2;
            } else if (ExpansionMethod == Linear) { // alot slower, but safer?
                newSize += ChunkSize;
            }
        }

        var newBuffer = new Uint8Array(newSize);
        newBuffer.set(buffer, 0);
        buffer = newBuffer;
    }

    private function toNativeArray():Uint8Array {
        return buffer.subarray(0, this.offset);
    }
}