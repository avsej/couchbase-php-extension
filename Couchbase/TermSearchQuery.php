<?php

/**
 * Copyright 2014-Present Couchbase, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

declare(strict_types=1);

namespace Couchbase;

/**
 * A facet that gives the number of occurrences of the most recurring terms in all hits.
 */
class TermSearchQuery implements JsonSerializable, SearchQuery
{
    public function jsonSerialize()
    {
    }

    public function __construct(string $term)
    {
    }

    /**
     * @param float $boost
     * @return TermSearchQuery
     */
    public function boost(float $boost): TermSearchQuery
    {
    }

    /**
     * @param string $field
     * @return TermSearchQuery
     */
    public function field(string $field): TermSearchQuery
    {
    }

    /**
     * @param int $prefixLength
     * @return TermSearchQuery
     */
    public function prefixLength(int $prefixLength): TermSearchQuery
    {
    }

    /**
     * @param int $fuzziness
     * @return TermSearchQuery
     */
    public function fuzziness(int $fuzziness): TermSearchQuery
    {
    }
}