# Breaking Decompilers

...or, How To Make My Life Difficult

----

<!-- .slide: data-background="/images/family.png" -->

Note: I'm Jordan

----

<!-- .slide: data-background-color="white" data-background-size="contain" data-background="/images/binja.png" -->

Note: I'm one of the developers behind Binary Ninja

---

## Goals

After this talk, you should:

- understand more about how decompilers work and thus,
- have lots of ideas on how to break them

---

## Outline

 - Why Decompilers Are Impossible
 - How Decompilers Work
 - (╯°□°）╯︵ ┻━┻ 

---

# Why Decompilers Are Impossible

----

## Informally

 - Comments
 - Symbol Names (in a stripped binary without debug)
 
Note: these are clearly and obviously lost but it's more than that, for example:
 
----

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

## How Decompilers Work

 - Parsing
 - ~Lifting~ Lowering
 - Optimizing

Note: What about now?

----

<!-- .slide: data-background-color="#212121" data-background-size="auto" data-background="/images/chatgpt-how-compilers-work.png" -->

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
 - P-Code, BNIL, Microcode
 - See [BlueHat Talk](https://www.youtube.com/watch?v=Q-FWpakkBFw) or [Updated Slides](https://docs.google.com/presentation/d/1O9G6Mljmxnd4gsgUXJl8adWP_BsynPn6fvVzaYQnoUs/edit#slide=id.p1)
