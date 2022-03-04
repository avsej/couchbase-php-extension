/* -*- Mode: C++; tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
 *   Copyright 2020-2021 Couchbase, Inc.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

#include <php.h>

#include <couchbase/version.hxx>
#include <couchbase/platform/terminate_handler.h>

#include <spdlog/spdlog.h>
#include <spdlog/cfg/env.h>

static void
init_logger()
{
    spdlog::set_pattern("[%Y-%m-%d %T.%e] [%P,%t] [%^%l%$] %oms, %v");

    auto env_val = spdlog::details::os::getenv("COUCHBASE_BACKEND_LOG_LEVEL");
    if (env_val.empty()) {
        spdlog::set_level(spdlog::level::info);
    } else {
        spdlog::cfg::helpers::load_levels(env_val);
    }

    env_val = spdlog::details::os::getenv("COUCHBASE_BACKEND_DONT_INSTALL_TERMINATE_HANDLER");
    if (env_val.empty()) {
        couchbase::platform::install_backtrace_terminate_handler();
    }
}

int
main()
{
    init_logger();

    for (const auto& [name, value] : couchbase::sdk_build_info()) {
        spdlog::critical("{}: {}", name, value);
    }
    spdlog::critical("php: {}", PHP_VERSION);

    return 0;
}
