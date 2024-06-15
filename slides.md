# Breaking Decompilers

...or, How To Make My Life Difficult

----

<!-- .slide: data-background-transition="none" data-background="/images/family.png" -->

Note: I'm Jordan

----

<!-- .slide: data-background-transition="none" data-background-color="white" data-background-size="contain" data-background="/images/binja.png" -->

Note: I'm one of the developers behind Binary Ninja

----

## You?

Who has...
- written C?
- used a debugger?
- used a decompiler?
- written a decompiler?
- written a decompiler plugin?

----

## Goals

After this talk, you should:

- understand more about how decompilers work and thus,
- have lots of ideas on how to break them

----

## Anti-Goals

- Not about breaking debuggers
- Not about an exhaustive list of all possible techniques

Note: While this talk isn't explicitly about breaking debuggers and we're not intentionally targeting them, it's worth noting that most debuggers are also disassemblers and have to parse files so several of these techniques will be applicable. 

Instead of showing off a ton of pre-built tools and an exhaustive list of all techniques I'll show a handful of examples that hopefully inspire new techniques.

----

## Outline

 - Why Decompilers Are Impossible
 - How Decompilers Work
 - `(╯°□°）╯︵ ┻━┻`

---

# Why Decompilers Are Impossible

----

## Informally

 - Comments
 - Symbol Names (in a stripped binary without debug)
 
Note: these are clearly and obviously lost but it's more than that, for example:
 
----

<!-- .slide: style="color:white" -->  

## Informally

```c
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  int fd = open(argv[1], O_RDONLY);
  size_t size = lseek(fd, 0, SEEK_END);
  int prot = PROT_EXEC | PROT_READ;
  void *mem = mmap(NULL, size, prot, MAP_PRIVATE, fd, 0);
  ((void(*)())mem)();
  return 0;
}
```

Note: Can you tell me all possible things this program will do?

----

## Formally

<a href="https://en.wikipedia.org/wiki/Rice's_theorem">https://en.wikipedia.org/wiki/Rice's_theorem</a>

Note: Rice's Theorem is an extension to the halting problem that basically proves that not only is it impossible to always be able to tell whether a program terminates, but you can't tell ANY non-trivial property of the program. So by this logic, we should never be able to perfectly analyze any program. 


----

## But...

Note: You all saw the outline, and you are almost certainly aware that decompilers exist. So how do I reconcile my two statements?
Thankfully, we don't have to be perfect, we just have to work most of the time. Most decompilers are written to operate best on standard compiler code which is much better formed than "all possible code" and therefore many shortcuts/heuristics can be taken.

---

# How Decompilers Work

----

## How Decompilers Work

 - Parsing
 - Lifting
 - Optimizing

Note: Sound familiar? No, really, anybody? Does this sound like any other programming technology? 

----

## How ~De~compilers Work

 - Parsing
 - ~Lifting~ Lowering
 - Optimizing

Note: What about now?

----

<!-- .slide: data-background-transition="none" data-background-color="#212121" data-background-size="contain" data-background-image="/images/chatgpt-how-compilers-work.png" -->

Note: Yup, that's exactly how a compiler works. It turns out, that there's a ton of similarity between building a compiler and a decompiler. Which makes sense since they're both having to translate from one representation into another. Just turns out, one is about putting the sausage back into the pig.

----

## Parsing

Universal:
 - Memory Mappings
 - Entry Point
 - Exports / Imports
 - Control Flow / Code Discovery
 
----

## Parsing 

Specific:
 - Mach-O / PE / ELF
 - Section Information
 - Metadata
 - Relocations

----

## Lifting

 - Translating from native to intermediate
 - BNIL, Microcode, P-Code
 - See [BlueHat Talk](https://www.youtube.com/watch?v=Q-FWpakkBFw) or [Updated Slides](https://docs.google.com/presentation/d/1O9G6Mljmxnd4gsgUXJl8adWP_BsynPn6fvVzaYQnoUs/edit#slide=id.p1)

Note: Way more than I can cover here, check out one of my previous talks for more info. Another phrasing for this might have been "translating", there's a translation step from native architecture to some intermediate representation. "P-Code" origin?

----

## Optimizing

- Applying type information
- Matching signatures
- Dead Code Elimination
- Resolve Indirect Control Flow
- Higher Level Control Flow Structures

Note: and several other topics worthy of an entire semester worth of advanced CS classes.

---

# Almost There!

Note: Before we actually break things, we do need to make sure we talk about different properties we might care about.

----

## Effective

How much does it prevent analysis/understanding?

![](/images/effectiveness-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->

Note: higher is better, so the higher the number, the more effective the obfuscation is at breaking analysis
----

## Evident

How obvious is it?

![](/images/evident-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->

Note: Pardon the awkward phrasing, I know "stealthy" works better, but this makes the three Es and the alliteration work better. Higher is better, so a higher number means the technique is less observable. Kinda backward, but this lets the scores be additive.  This is one of the most important attributes as too often people just want to make it hard to reverse something, but what is far more valuable is _subtly_ breaking a decompiler. That, used judiciously, can cause far more trouble than the world's most opaque VM implementation.

----

## Effort

How much work is it to implement? 

![](/images/effort-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->


Note: Pardon the awkward phrasing, I know "stealthy" works better, but this makes the three Es and the alliteration work better. Higher is better, so a higher number means the technique is less observable. Kinda backward, but this lets the scores be additive. 

---

## `(╯°□°）╯︵ ┻━┻`

Note: Ok, with that out of the way, let's actually go break some decompilers.

----

## Base Challenge

```c
#include <stdio.h>
#include <string.h>

int main() {
    char input[100];
    printf("Enter the password: ");
    fgets(input, sizeof(input), stdin);
    if (strcmp(input, "correct") == 0) {
        printf("Access granted!\n");
    } else {
        printf("Access denied!\n");
    }
    return 0;
}
```

Note: not quite exactly what we're using, but close enough and fits on a slide. We're going to take this same challenge and apply a bunch of our techniques to it and see how it looks after each.

---

## Break the Parsing

----

### Segment Shenanigans

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>5</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>5</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>1</td></tr>
</table>

Note: Found accidentally by zetatwo / Calle when making a CTF challenge, but there's a million other variants. I think this is one of my favorite techniques specifically because it's not at all obvious something is even wrong in the first place. You can make the difference between the real code and fake code super subtle if you like. Of course, just running in a debugger should be enough to spot the differences.  Note evident at all! Can be extremely subtle if you want it to be.

----

#### Demo! 

`./examples/zetatwo`

----

### Relocations

Relocations are the worst

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>5</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>5</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>1</td></tr>
</table>

Note: A pain to implement but infinitely complex

----

### Build Your Own!

1. Fuzz the file, run it. 
1. If it still works, dump the decompilation and pattern match
1. GOTO 1

---

## Break the Lifting

----

### Alignment 

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>3</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

Note: oldest trick in the book, still breaks IDA super easily! At one point they "fixed" it by matching the exact byte pattern match (turns out, they only did it on x86, x64 is still vulnerable to the same thing)

----

#### Demo!

`./examples/alignment`

----

### Vectorized

Just use an instruction that is rare and not implemented, or is incorrectly lifted.

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>3</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>2</td></tr>
</table>

Note: similar in terms of effectiveness to mis-aligned instructions, depends on the tool and how it gets the lifting wrong. More work than the mis-aligned instructions because you have to find the instructions first, but you can probably just go trolling through libraries or bug reports for Binja or Ghidra. Or just use consensus evaluation and disassembly a single instruction at a time in LOTS of tools. Does require normalization though which can be a headache. That said, relatively easy to fix on the architecture/parsing side.

---

## Break the Optimizations

----

### STOP 🛑

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>3</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>2</td></tr>
</table>

`./examples/stop`

Note: The particular optimization being abused here is in the "no-return" property as well as the fact that IDA's heuristic for when to apply the type is permissive. Of course, on the flip-side, there are potentially binaries where static signatures don't apply where's IDA's heuristic might result in better analysis. Most of these are simply choices that the tools make to decide what they think is the best default case but they can easily be abused.

----

#### Demo!

----

### UPX

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

`./examples/upx`

----

#### Demo!

----

### SCC

Similar to Jon's talk, but many people don't know SCC has a variety of obfuscations built in.

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>


----

### Dataflow Propagation/Memory Permissions

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

----

#### Demo!

`./examples/perms`

----

### SCC

<table>
<tr><td><img src="/images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="/images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="/images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

----

#### Demo!

`./examples/scc`

---

## Conclusion

- What are your goals?
- Do you care more about increased difficulty or subtle breakage?
- Decompilers are easy to break, hard to make.

----

## Questions?

https://github.com/psifertex/breaking_decompilers

----

## Credits / Acknowledgements

- [reveal-md](https://github.com/webpro/reveal-md)
- [lima](https://github.com/lima-vm/lima)
- [chatgpt](https://chat.openai.com/)
