# Breaking Decompilers

...or, How To Make Jordan's Life Hard

----

<!-- .slide: data-background-transition="none" data-background="./images/family.png" -->

Note: I'm Jordan!

----

<!-- .slide: data-background-transition="none" data-background-color="white" data-background-size="contain" data-background="./images/binja.png" -->

Note: I'm one of the developers behind Binary Ninja. I also believe the best talks have the shortest biography sections.

----

## You?

Who has...
- written C?
- used a debugger?
- used a decompiler?
- written a plugin for a decompiler?
- written a decompiler?

Note: I have the coveted "after lunch" spot where everyone is usually very sleepy so let's see if we can wake up by moving a little bit. I'd like some audience participation. By a show of hands, please show...

----

## Goals

After this talk, you should:

- understand more about how decompilers work and thus,
- have lots of ideas on how to break them
- know a bunch of concrete examples that will break all tools

Note: Goals for this talk. 

----

## Anti-Goals

- Not breaking debuggers
- Not an exhaustive list of all possible techniques

Note: While this talk isn't explicitly about breaking debuggers and we're not intentionally targeting them, it's worth noting that most debuggers are also disassemblers and have to parse files so several of these techniques will still apply. However, there are other techniques that are only applicable in dynamic analysis situations.

----

## Outline

 - Why Decompilers Are Impossible
 - How Decompilers Work At All
 - `(╯°□°）╯︵ ┻━┻`

---

# Why Decompilers Are Impossible

----

## Informally

 - Comments
 - Symbol Names (in a stripped binary without debug info)
 
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

## Code? Data?

<br />
<br />
<br />
<br />
<br />
<br />
<br />

<!-- .slide: data-background-transition="none" data-background-color="#212121" data-background-size="contain" data-background-image="./images/codeid.gif" -->

Note: One of the hardest problems in computer science is "what is code" and "what is data". This isn't maybe super obvious since we're all used to just seeing analysis tools scan and find the code but for a whole bunch of reasons I'm not going to go into now, this is actually a very difficult problem.

Definitely some folks who have researched this but there's plenty of folks who also just blindly assume it's solved:
- https://link.springer.com/content/pdf/10.1007/978-3-642-23808-6_34.pdf
- https://www.usenix.org/system/files/sec22-pang-chengbin.pdf

----

## But...

Note: You all saw the outline, and you are almost certainly aware that decompilers exist. So how do I reconcile my two statements?

Thankfully, we don't have to be perfect, we just have to work most of the time. Most decompilers are written to operate best on standard compiler code which is much better formed than "all possible code" and therefore many shortcuts/heuristics can be taken. Often, these assumptions are the very things we'll be abusing.

---

# How Decompilers Work At All

----

## How Decompilers Work At All

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

<!-- .slide: data-background-transition="none" data-background-color="#212121" data-background-size="contain" data-background-image="./images/chatgpt-how-compilers-work.png" -->

Note: Yup, that's exactly how a compiler works. It turns out, that there's a ton of similarity between building a compiler and a decompiler. Which makes sense since they're both having to translate from one representation into another.

----

## Parsing

Universal:
 - Memory Mappings
 - Entry Point
 - Exports / Imports
 - Control Flow / Code Discovery
 
Note: So let's look at some opportunities of what parsing, lifting, and optimizing look like in terms of attack surface to break decompilers. Someone actually asked me yesterday if this was more about breaking decompilation or disassembly, and it was a good question. We'll be focusing on both as you can tell from this list!

Control Flow / Code Discovery could be considered partially a lifting problem, partially a parsing problem, so we'll list it in both places.

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

This is in particular where we're targeting the decompiler aspect specifically even though the previous steps are also pre-requisites for decompilation they will also break disassemblers.

---

# Evaluation Criteria

Note: Before we actually break things, let's talk about the different properties we might care about regarding obfuscation.

----

## Effective

How much does it prevent analysis/understanding?

![](./images/effectiveness-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->

----

## Effective

Strength of Effect on understanding/analysis:
1. Ineffective
1. Somewhat Effective 
1. Moderately effective 
1. Very effective
1. Extremely effective

Note: higher is better, so the higher the number, the more effective the obfuscation is at breaking analysis

----

## Evident

How obvious is it?

![](./images/evident-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->

----

## Evident

1. Blatant
1. Clear
1. Noticeable
1. Subtle
1. Hidden

Note: This is one of the most important attributes as too often people just want to make it hard to reverse something, but what is far more valuable is _subtly_ breaking a decompiler. That, used judiciously, can cause far more trouble than the world's most opaque VM implementation.

----

## Effort

How much work is it to implement? 

![](./images/effort-light.png)
<!-- .element: style="width: 150px;margin: 0 auto;" -->

----

## Effort 

1. Trivial
1. Light
1. Moderate
1. Demanding
1. Grueling

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

## Examples

 - Break Parsing
   - Sections/Segments
   - Relocations
 - Break Lifting
   - Alignment
   - Vectorization
 - Break Optimizations
   - What's in a Name?
   - Packers
   - Permissions/Dataflow
   - Non-Standard Compiler

---

## Break the Parsing

----

### Relocations

Relocations are the worst

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>5</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>1</td></tr>
</table>

Note: A pain to implement, I'm not even going to make any examples, but this is probably one of the most under-appreciated tools to use to break decompilers, in part because every architecture and platform implements them differently and there are way way more than you think.

----
### Section Shenanigans

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>3</td></tr>
</table>

Note: Many folks have created variants by this. It was pointed out to my by zetatwo who worked with bluec0re for the example documented in PagedOut 5, and it was also documented in an earlier PoC||GTFO 

----

#### Demo! 

[`./examples/sections`](https://github.com/psifertex/breaking_decompilers/tree/master/examples/sections)

----

### Build Your Own!

1. Fuzz the file, run it. 
1. If it still works, dump the decompilation and pattern match.
1. GOTO 1

Note: There are an infinite number of discrepencies between loaders and decompilers. All it takes is playing around with new features and you can find a new break here pretty easily.

---

## Break the Lifting

----

### Alignment

<!-- .slide: data-auto-animate -->

<!-- Using a completely different approach with separate divs -->
<div style="text-align: center; height: 8em; position: relative;">
  <!-- Original bytes - always visible -->
  <div style="margin-bottom: 3em;">
    <code style="font-family: monospace;">eb ff c3</code>
  </div>
  
  <!-- First interpretation - only visible for fragment 1 -->
  <div class="fragment fade-in-then-out" data-fragment-index="1" style="position: absolute; width: 100%; top: 3em;">
    <div>
      <code style="font-family: monospace;"><span style="color:#ff5555">eb ff</span> <span style="color:#888888">c3</span></code>
    </div>
    <div style="font-size: 0.8em; margin-top: 0.5em;">
      <code>jmp $-1
      ret</code>
    </div>
  </div>
  
  <!-- Second interpretation - only visible for fragment 2 -->
  <div class="fragment fade-in" data-fragment-index="2" style="position: absolute; width: 100%; top: 3em;">
    <div>
      <code style="font-family: monospace;"><span style="color:#888888">eb</span> <span style="color:#5555ff">ff c3</span></code>
    </div>
    <div style="font-size: 0.8em; margin-top: 0.5em;">
      <code>inc ebx</code>
    </div>
  </div>
</div>

Note: This example shows how the same byte sequence can be interpreted in multiple ways. The bytes "eb ff c3" can be read as two different instruction sequences depending on the disassembly technique.

----
### Alignment 

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>3</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>3</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

Note: oldest trick in the book, still breaks IDA super easily! At one point they "fixed" it by matching the exact byte pattern match (turns out, they only did it on x86, x64 is still vulnerable to the same thing)

Ghidra used to be vulnerable but fixed it at some point.

----

#### Demo!

[`./examples/alignment`](https://github.com/psifertex/breaking_decompilers/tree/master/examples/alignment)

[🐶⚡️ Link](https://dogbolt.org/?id=aef96f4f-e7d5-4fbc-a251-889a2c71ee4e#BinaryNinja=136&Hex-Rays=27)

Note: I have no idea what IDA is doing here. It simply refuses to decompile it at all. 

----

### Vectorized

Just use an instruction that is rare and not implemented, or is incorrectly lifted.

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>5</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>1</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>3</td></tr>
</table>

Note: similar in terms of effectiveness to mis-aligned instructions, depends on the tool and how it gets the lifting wrong. More work than the mis-aligned instructions because you have to find the instructions first, but you can probably just go trolling through libraries or bug reports for Binja or Ghidra. Or just use consensus evaluation and disassembly a single instruction at a time in LOTS of tools. Does require normalization though which can be a headache. That said, relatively easy to fix on the architecture/parsing side.

----

#### Demo! 

[`./examples/vectorized`](https://github.com/psifertex/breaking_decompilers/tree/master/examples/vectorized)

[🐶⚡️ Link](https://dogbolt.org/?id=d2ad9c20-4e15-493f-8af1-93d3a5de8fbb#Hex-Rays=195&BinaryNinja=183&Ghidra=231)

---

## Break the Optimizations

----

### STOP 🛑

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>3</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>2</td></tr>
</table>

Note: The particular optimization being abused here is in the "no-return" property as well as the fact that IDA's heuristic for when to apply the type is permissive. Of course, on the flip-side, there are potentially binaries where static signatures don't apply where's IDA's heuristic might result in better analysis. Most of these are simply choices that the tools make to decide what they think is the best default case but they can easily be abused.

----

#### Demo!

`./examples/stop`

[🐶⚡️ Link](https://dogbolt.org/?id=5149a9c7-84ce-4acf-9e47-7312a6b97315#BinaryNinja=141&Hex-Rays=158&angr=136&Ghidra=114)

----

### UPX

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

`./examples/upx`

----

#### Demo!

----

### SCC

Our newly [open-sourced](https://github.com/Vector35/scc) Shellcode Compiler supports many built in obfuscations.

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>2</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>5</td></tr>
</table>

Note: Has many built-in obfuscations. But really this is just a substitute for any obfuscating compiler. In this case I'm just using a single option to use a different register for the stack pointer. That's it, but because this is a non-standard compiler technique, any decompilers that assume the stack pointer must be EBP/RSP will have lots of trouble.

----

### SCC

[https://scc.binary.ninja/scc.html](https://scc.binary.ninja/scc.html)

----

##### Demo! 

[🐶⚡️ Link](https://dogbolt.org/?id=ab0bf805-4f06-4c94-81d0-380bff9e2944#BinaryNinja=1&Ghidra=5&Hex-Rays=28)

----

### Dataflow Propagation/Memory Permissions

<table>
<tr><td><img src="./images/effectiveness-light.png" style="width: 50px; margin: 0px"></td><td>Effective</td><td>4</td></tr>
<tr><td><img src="./images/evident-light.png" style="width: 50px; margin: 0px;"></td><td>Evident</td><td>4</td></tr>
<tr><td><img src="./images/effort-light.png" style="width: 50px; margin: 0px;"></td><td>Effort</td><td>4</td></tr>
</table>

----

#### Demo!

`./examples/dataflow`

[🐶⚡️ Link](https://dogbolt.org/?id=4c7ce171-9207-4d32-8736-ab9439bc4d2b#Ghidra=220&Hex-Rays=200&BinaryNinja=185)

---

## Bonus: Breaking LLMs

"Multi Level Marketing Model"


- [🎥 Video](https://www.youtube.com/watch?v=M0akm0QgkUU&t=159)
- [🧑‍💻 Source Code](https://github.com/Live-CTF/LiveCTF-DEFCON33)

Note: Time permitting, share example of MLMM and how it turned out it wasn't even needed!

---

## Summary of Techniques

<style>
.reveal table {
  font-size: 0.7em;
}
</style>

| Technique | Effectiveness | Evident | Effort |
|-----------|--------------|---------|--------|
| Section Shenanigans | 4 | 4 | 3 |
| Relocations | 5 | 4 | 1 |
| Alignment | 3 | 3 | 5 |
| Vectorized | 5 | 1 | 3 |
| STOP | 3 | 2 | 2 |
| UPX | 4 | 4 | 5 |
| SCC | 4 | 2 | 5 |
| Dataflow/Permissions | 4 | 4 | 4 |

Note: Higher scores are better in all categories.

---

## Conclusion

- What are your goals?
- Do you care more about increased difficulty or subtle breakage?
- Decompilers are easy to break, hard to make.

----

## Questions?

- https://github.com/psifertex/breaking_decompilers
- https://twitter.com/psifertex
- https://binary.ninja/

![](./images/repo-light.png)

Note: Please note that I'd love feedback if you have other examples of things that break binary ninja besides this. As a side-note, we do treat 

----

## Credits / Acknowledgements

- [reveal-md](https://github.com/webpro/reveal-md)
- [podman](https://podman.io/)
- [chatgpt](https://chat.openai.com/) (o4-mini for image generation)

Note: We all stand on the shoulders of giants, I'm sure none of these techniques are new, thanks to everyone else who has done similar research in the past, sorry for not running down each instance, if I had I was afraid I would miss some other earlier example!
