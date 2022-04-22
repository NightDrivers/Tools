//
//  main.m
//  Tools
//
//  Created by ldc on 2021/1/19.
//

#import <Foundation/Foundation.h>

struct Node {
    int value;
    struct Node *next;
};

struct List {
    
    int length;
    struct Node *next;
};

struct Node *createNode(void) {
    struct Node *header = (struct Node *)calloc(sizeof(struct Node), 1);
    (*header).value = 0;
    (*header).next = NULL;
    return header;
}

struct Node *listGetLastNode(struct Node *list) {
    
    struct Node *node = list;
    while ((*node).next != NULL) {
        node = (*node).next;
    }
    return node;
}

void listAppend(struct Node *list, struct Node *node) {
    
    struct Node *last = listGetLastNode(list);
    (*last).next = node;
}

int listRemove(struct Node *list, struct Node *node) {
    
    struct Node *_node = list;
    struct Node *previousNode;
    while ((*_node).next != NULL) {
        previousNode = _node;
        _node = (*_node).next;
        if (_node == node) {
            (*previousNode).next = (*_node).next;
            free(node);
            return 0;
        }
    }
    return -1;
}

int listRemoveWithIndex(struct Node *list, int index) {
    
    if (index < 0) {
        return 0;
    }
    struct Node *_node = list;
    struct Node *previousNode;
    int i = -1;
    while ((*_node).next != NULL) {
        previousNode = _node;
        _node = (*_node).next;
        i++;
        if (i == index) {
            (*previousNode).next = (*_node).next;
            free(_node);
            return 0;
        }
    }
    return -1;
}

void listTraverse(struct Node *list) {
    
    struct Node *node = list;
    while ((*node).next != NULL) {
        node = (*node).next;
        NSLog(@"%i\n", (*node).value);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        struct Node *list = createNode();
        (*list).value = 0;
//        printf("%p-%i\n", list, (*list).value);
        
        struct Node *node = createNode();
        (*node).value = 1;
        listAppend(list, node);
        
        node = createNode();
        (*node).value = 2;
        listAppend(list, node);
        
        node = createNode();
        (*node).value = 3;
        listAppend(list, node);
        
        listRemoveWithIndex(list, 0);
        listRemoveWithIndex(list, 1);
        
        listTraverse(list);
    }
    return 0;
}
