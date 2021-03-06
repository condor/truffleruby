/*
 * Copyright (c) 2014, 2018 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0, or
 * GNU General Public License version 2, or
 * GNU Lesser General Public License version 2.1.
 */
package org.truffleruby.language.backtrace;

import com.oracle.truffle.api.nodes.Node;
import com.oracle.truffle.api.object.DynamicObject;
import com.oracle.truffle.api.source.SourceSection;
import org.truffleruby.RubyContext;
import org.truffleruby.language.RubyBaseNode;
import org.truffleruby.language.backtrace.BacktraceFormatter.FormattingFlags;

import java.util.EnumSet;

public class Backtrace {

    private final Node location;
    private SourceSection sourceLocation;
    private final Activation[] activations;
    private final int omitted;
    private final Throwable javaThrowable;
    private DynamicObject backtraceStringArray;

    public Backtrace(Node location, SourceSection sourceLocation, Activation[] activations, int omitted, Throwable javaThrowable) {
        this.location = location;
        this.sourceLocation = sourceLocation;
        this.activations = activations;
        this.omitted = omitted;
        this.javaThrowable = javaThrowable;
    }

    public Node getLocation() {
        return location;
    }

    public SourceSection getSourceLocation() {
        return sourceLocation;
    }

    /**
     * Returns an array to PE better. Do not modify it.
     */
    public Activation[] getActivations() {
        return activations;
    }

    public int getActivationCount() {
        return activations.length;
    }

    public Activation getActivation(int index) {
        return activations[index];
    }

    public int getOmitted() {
        return omitted;
    }

    public Throwable getJavaThrowable() {
        return javaThrowable;
    }

    @Override
    public String toString() {
        RubyContext context = null;
        if (activations.length > 0) {
            Activation activation = activations[0];
            Node node = activation.getCallNode();
            if (node != null && node instanceof RubyBaseNode) {
                context = ((RubyBaseNode) node).getContext();
            }
        }

        if (context != null) {
            final BacktraceFormatter backtraceFormatter = new BacktraceFormatter(context, EnumSet.of(FormattingFlags.INCLUDE_CORE_FILES));
            final StringBuilder builder = new StringBuilder();
            for (String line : backtraceFormatter.formatBacktrace(context, null, this)) {
                builder.append("\n");
                builder.append(line);
            }
            return builder.toString().substring(1);
        } else {
            return "";
        }
    }

    public DynamicObject getBacktraceStringArray() {
        return backtraceStringArray;
    }

    public void setBacktraceStringArray(DynamicObject backtraceStringArray) {
        this.backtraceStringArray = backtraceStringArray;
    }

}
