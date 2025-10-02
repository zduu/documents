#!/usr/bin/env bash

# Docker 操作菜单脚本 (v3)
#
# 功能:
# 提供一个交互式菜单，用于执行常见的 Docker 及 Docker Compose 操作，
# 具有更友好的交互提示和界面。
# 支持 Linux 和 macOS 系统，自动检测 Docker 和 Docker Compose。

# 自动赋予执行权限
if [ ! -x "$0" ]; then
    chmod +x "$0"
    echo "已自动赋予脚本执行权限"
    exec "$0" "$@"
fi

# 检查并修复失效的快捷指令
check_and_fix_shortcut() {
    local bin_dir="$HOME/.local/bin"
    local shortcut_name="dk"
    local shortcut_path="$bin_dir/$shortcut_name"

    # 如果快捷指令存在但指向的文件不存在
    if [ -L "$shortcut_path" ]; then
        local target=$(readlink "$shortcut_path")
        if [ ! -f "$target" ]; then
            local current_script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}⚠️  检测到快捷指令已失效${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}原路径: ${target}${NC}"
            echo -e "${GREEN}新路径: ${current_script}${NC}"
            echo -e "${BLUE}是否自动修复? (y/n, 默认 y):${NC}"
            read -r -t 10 fix_choice || fix_choice="y"
            if [[ "$fix_choice" != "n" && "$fix_choice" != "N" ]]; then
                ln -sf "$current_script" "$shortcut_path"
                echo -e "${GREEN}✓ 快捷指令已自动修复！${NC}\n"
                sleep 2
            fi
        fi
    fi
}

# 执行检查
check_and_fix_shortcut

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        *)          OS="Unknown";;
    esac
}

# 检测 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未检测到 Docker，请先安装 Docker。${NC}"
        echo -e "${YELLOW}安装指南:${NC}"
        echo -e "  Linux: https://docs.docker.com/engine/install/"
        echo -e "  macOS: https://docs.docker.com/desktop/install/mac-install/"
        exit 1
    fi

    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 未运行，请先启动 Docker 服务。${NC}"
        if [ "$OS" = "macOS" ]; then
            echo -e "${YELLOW}提示: 请打开 Docker Desktop 应用${NC}"
        else
            echo -e "${YELLOW}提示: 运行 'sudo systemctl start docker'${NC}"
        fi
        exit 1
    fi
}

# 检测 Docker Compose 命令
detect_compose_cmd() {
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${YELLOW}警告: 未检测到 Docker Compose，相关功能将不可用。${NC}"
        COMPOSE_CMD=""
    fi
}

# 初始化检测
detect_os
check_docker
detect_compose_cmd

# 安装快捷指令
install_shortcut() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        安装快捷指令                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    local script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local bin_dir="$HOME/.local/bin"
    local shortcut_name="dk"

    # 检查是否已安装
    if [ -L "$bin_dir/$shortcut_name" ]; then
        echo -e "${YELLOW}⚠ 快捷指令已存在${NC}"
        echo -e "${BLUE}当前指向: ${CYAN}$(readlink "$bin_dir/$shortcut_name")${NC}"
        echo -e "${BLUE}是否重新安装? (y/n, 默认 n):${NC}"
        read -r reinstall
        if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
            echo -e "${YELLOW}已取消安装${NC}"
            return
        fi
    fi

    # 创建 bin 目录
    mkdir -p "$bin_dir"

    # 创建软链接
    ln -sf "$script_path" "$bin_dir/$shortcut_name"
    echo -e "${GREEN}✓${NC} 创建软链接: ${CYAN}$bin_dir/$shortcut_name${NC}"

    # 检测 shell 类型并添加 PATH
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ "$OS" = "macOS" ]; then
            shell_rc="$HOME/.bash_profile"
        else
            shell_rc="$HOME/.bashrc"
        fi
    fi

    # 添加到 PATH
    if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
        # 检查是否已经包含 Docker 脚本快捷指令的配置
        if ! grep -q "# Docker 脚本快捷指令" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Docker 脚本快捷指令" >> "$shell_rc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            echo -e "${GREEN}✓${NC} 已添加 PATH 到 ${CYAN}$shell_rc${NC}"
        else
            echo -e "${GREEN}✓${NC} PATH 已存在于 ${CYAN}$shell_rc${NC}"
        fi
    fi

    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ 快捷指令安装成功！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${YELLOW}📌 快捷指令名称: ${CYAN}${shortcut_name}${NC}"
    echo -e "\n${YELLOW}🔧 使配置生效 (二选一):${NC}"
    echo -e "   ${CYAN}1.${NC} 运行命令: ${CYAN}source $shell_rc${NC}"
    echo -e "   ${CYAN}2.${NC} 重新打开终端"
    echo -e "\n${YELLOW}🚀 之后可以在任何位置直接运行: ${GREEN}${shortcut_name}${NC}"
}

# 删除快捷指令
uninstall_shortcut() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        删除快捷指令                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    local bin_dir="$HOME/.local/bin"
    local shortcut_name="dk"

    # 检查是否已安装
    if [ ! -L "$bin_dir/$shortcut_name" ] && [ ! -f "$bin_dir/$shortcut_name" ]; then
        echo -e "${YELLOW}⚠ 未找到快捷指令 '${shortcut_name}'${NC}"
        return
    fi

    echo -e "${BLUE}当前快捷指令: ${CYAN}$bin_dir/$shortcut_name${NC}"
    if [ -L "$bin_dir/$shortcut_name" ]; then
        echo -e "${BLUE}指向: ${CYAN}$(readlink "$bin_dir/$shortcut_name")${NC}"
    fi

    echo -e "\n${RED}确认删除快捷指令? (y/n, 默认 n):${NC}"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}已取消删除${NC}"
        return
    fi

    # 删除软链接
    rm -f "$bin_dir/$shortcut_name"
    echo -e "\n${GREEN}✓ 已删除快捷指令: ${CYAN}$shortcut_name${NC}"

    echo -e "\n${YELLOW}💡 提示: PATH 配置保留在 shell 配置文件中，不影响其他程序${NC}"
    echo -e "${YELLOW}   如需完全清理，请手动从以下文件中删除相关配置:${NC}"
    echo -e "   ${CYAN}~/.zshrc 或 ~/.bashrc 或 ~/.bash_profile${NC}"
}

# 通用函数：提示按任意键继续
press_any_key_to_continue() {
    echo -e "\n${YELLOW}按任意键返回主菜单...${NC}"
    read -n 1 -s -r
}

# 1. 构建镜像
build_image() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🏗️  构建镜像                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${BLUE}请输入镜像标签 (例如: my-app:1.0):${NC}"
    read -r image_tag
    if [ -z "$image_tag" ]; then
        echo -e "${RED}❌ 错误：镜像标签不能为空。${NC}"
        return
    fi

    echo -e "${BLUE}请输入 Dockerfile 所在目录的路径 (默认为当前目录 '.'):${NC}"
    read -r dockerfile_path
    dockerfile_path=${dockerfile_path:-.}

    echo -e "\n${YELLOW}🚀 正在执行: docker build -t \"$image_tag\" \"$dockerfile_path\"${NC}\n"
    docker build -t "$image_tag" "$dockerfile_path"
}

# 2. 运行容器
run_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🚀 运行容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 本地镜像列表:${NC}"
    docker images
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要运行的镜像名称 (例如: my-app:1.0):${NC}"
    read -r image_name
    if [ -z "$image_name" ]; then
        echo -e "${RED}❌ 错误：镜像名称不能为空。${NC}"
        return
    fi

    echo -e "${BLUE}请输入容器名称 (可选):${NC}"
    read -r container_name
    [ -n "$container_name" ] && name_arg="--name $container_name" || name_arg=""

    echo -e "${BLUE}请输入要映射的端口 (例如: 8080:80) (可选):${NC}"
    read -r port_mapping
    [ -n "$port_mapping" ] && port_arg="-p $port_mapping" || port_arg=""

    echo -e "${BLUE}是否后台运行 (-d)? (y/n, 默认 y):${NC}"
    read -r detach_mode
    [[ "$detach_mode" == "n" || "$detach_mode" == "N" ]] && detach_arg="" || detach_arg="-d"

    echo -e "\n${YELLOW}🚀 正在执行: docker run $detach_arg $port_arg $name_arg $image_name${NC}\n"
    docker run $detach_arg $port_arg $name_arg "$image_name"
}

# 3. 停止容器
stop_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🛑 停止容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 正在运行的容器:${NC}"
    docker ps
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要停止的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}🛑 正在执行: docker stop \"$container_id\"${NC}\n"
    docker stop "$container_id"
}

# 4. 启动已停止的容器
start_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        ▶️  启动容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 所有已停止的容器:${NC}"
    docker ps -f "status=exited"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要启动的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}▶️  正在执行: docker start \"$container_id\"${NC}\n"
    docker start "$container_id"
}

# 5. 重启容器
restart_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🔄 重启容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 正在运行的容器:${NC}"
    docker ps
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要重启的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}🔄 正在执行: docker restart \"$container_id\"${NC}\n"
    docker restart "$container_id"
}

# 6. 查看容器日志
view_logs() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        📜 查看容器日志                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 正在运行的容器:${NC}"
    docker ps
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要查看日志的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}📜 正在执行: docker logs -f \"$container_id\"${NC}"
    echo -e "${YELLOW}💡 提示: 按 Ctrl+C 停止查看日志${NC}\n"
    docker logs -f "$container_id"
}

# 7. 进入容器
exec_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        💻 进入容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 正在运行的容器:${NC}"
    docker ps
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要进入的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi

    echo -e "${BLUE}请输入要执行的命令 (默认为 /bin/bash):${NC}"
    read -r command
    command=${command:-/bin/bash}

    echo -e "\n${YELLOW}💻 正在执行: docker exec -it \"$container_id\" $command${NC}\n"
    docker exec -it "$container_id" $command
}

# 8. 删除容器
remove_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🗑️  删除容器                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 所有容器 (包括已停止的):${NC}"
    docker ps -a
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要删除的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}🗑️  正在执行: docker rm \"$container_id\"${NC}\n"
    docker rm "$container_id"
}

# 9. 查看运行中的容器
list_running_containers() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     📋 正在运行的容器                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    docker ps
}

# 10. 查看所有容器
list_all_containers() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     📋 所有容器 (包括已停止)              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    docker ps -a
}

# 11. 查看本地镜像
list_images() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     📋 本地镜像列表                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    docker images
}

# 12. 拉取镜像
pull_image() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        📥 拉取镜像                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${BLUE}请输入要拉取的镜像名称 (例如: nginx:latest):${NC}"
    read -r image_name
    if [ -z "$image_name" ]; then
        echo -e "${RED}❌ 错误：镜像名称不能为空。${NC}"
        return
    fi

    echo -e "\n${YELLOW}📥 正在执行: docker pull \"$image_name\"${NC}\n"
    docker pull "$image_name"

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ 镜像拉取成功！${NC}"
    else
        echo -e "\n${RED}❌ 镜像拉取失败${NC}"
    fi
}

# 13. 删除镜像
remove_image() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🗑️  删除镜像                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📋 本地镜像列表:${NC}"
    docker images
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "${BLUE}请输入要删除的镜像名称或 ID:${NC}"
    read -r image_id
    if [ -z "$image_id" ]; then
        echo -e "${RED}❌ 错误：镜像名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}🗑️  正在执行: docker rmi \"$image_id\"${NC}\n"
    docker rmi "$image_id"
}

# 14. 资源监控
monitor_resources() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        📊 容器资源监控                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}💡 提示: 实时监控容器 CPU、内存、网络等资源使用情况${NC}"
    echo -e "${YELLOW}💡 按 Ctrl+C 退出监控${NC}\n"

    sleep 2
    docker stats
}

# 15. 磁盘使用分析
disk_usage_analysis() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        💾 磁盘使用分析                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📊 Docker 磁盘使用情况:${NC}\n"
    docker system df -v

    echo -e "\n${CYAN}────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}💡 提示: 如需清理未使用的资源，请使用系统清理功能${NC}"
}

# 16. 系统清理
system_cleanup() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🧹 系统清理                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}📊 当前磁盘使用情况:${NC}\n"
    docker system df

    echo -e "\n${CYAN}────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}⚠️  即将清理以下内容:${NC}"
    echo -e "  ${BLUE}•${NC} 已停止的容器"
    echo -e "  ${BLUE}•${NC} 未使用的网络"
    echo -e "  ${BLUE}•${NC} 悬空镜像 (dangling images)"
    echo -e "  ${BLUE}•${NC} 未使用的构建缓存"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "\n${BLUE}选择清理级别:${NC}"
    echo -e "  ${YELLOW}1.${NC} 标准清理 (保留未使用的镜像)"
    echo -e "  ${YELLOW}2.${NC} 深度清理 (删除所有未使用的镜像)"
    echo -e "  ${YELLOW}3.${NC} 完全清理 (包括数据卷，危险！)"
    echo -e "  ${YELLOW}0.${NC} 取消"

    echo -n -e "\n${BLUE}请选择 [0-3]: ${NC}"
    read -r cleanup_level

    case $cleanup_level in
        1)
            echo -e "\n${YELLOW}🧹 执行标准清理...${NC}\n"
            docker system prune -f
            ;;
        2)
            echo -e "\n${RED}确认深度清理? 将删除所有未使用的镜像 (y/n):${NC}"
            read -r confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "\n${YELLOW}🧹 执行深度清理...${NC}\n"
                docker system prune -af
            else
                echo -e "${YELLOW}已取消${NC}"
                return
            fi
            ;;
        3)
            echo -e "\n${RED}⚠️  警告: 完全清理将删除所有未使用的数据卷！${NC}"
            echo -e "${RED}确认执行? (输入 YES 确认):${NC}"
            read -r confirm
            if [ "$confirm" == "YES" ]; then
                echo -e "\n${YELLOW}🧹 执行完全清理...${NC}\n"
                docker system prune -af --volumes
            else
                echo -e "${YELLOW}已取消${NC}"
                return
            fi
            ;;
        0)
            echo -e "${YELLOW}已取消清理${NC}"
            return
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            return
            ;;
    esac

    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ 清理完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${YELLOW}📊 清理后磁盘使用:${NC}\n"
    docker system df
}

# 17. 服务彻底清除
complete_removal() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🗑️  服务彻底清除                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${RED}⚠️  此功能将彻底删除指定服务的所有相关资源！${NC}\n"

    echo -e "${BLUE}请输入要清除的服务关键词 (如: nginx, mysql):${NC}"
    read -r service_keyword

    if [ -z "$service_keyword" ]; then
        echo -e "${RED}❌ 错误：服务关键词不能为空。${NC}"
        return
    fi

    echo -e "\n${YELLOW}🔍 搜索相关资源...${NC}\n"

    # 查找相关容器
    echo -e "${CYAN}📦 相关容器:${NC}"
    matching_containers=$(docker ps -a --filter "name=$service_keyword" --format "{{.ID}}\t{{.Names}}\t{{.Status}}")
    if [ -n "$matching_containers" ]; then
        echo "$matching_containers" | nl
    else
        echo -e "${YELLOW}  未找到${NC}"
    fi

    # 查找相关镜像
    echo -e "\n${CYAN}🖼️  相关镜像:${NC}"
    matching_images=$(docker images --filter "reference=*$service_keyword*" --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}")
    if [ -n "$matching_images" ]; then
        echo "$matching_images" | nl
    else
        echo -e "${YELLOW}  未找到${NC}"
    fi

    # 查找相关网络
    echo -e "\n${CYAN}🌐 相关网络:${NC}"
    matching_networks=$(docker network ls --filter "name=$service_keyword" --format "{{.ID}}\t{{.Name}}")
    if [ -n "$matching_networks" ]; then
        echo "$matching_networks" | nl
    else
        echo -e "${YELLOW}  未找到${NC}"
    fi

    # 查找相关数据卷
    echo -e "\n${CYAN}💾 相关数据卷:${NC}"
    matching_volumes=$(docker volume ls --filter "name=$service_keyword" --format "{{.Name}}")
    if [ -n "$matching_volumes" ]; then
        echo "$matching_volumes" | nl
    else
        echo -e "${YELLOW}  未找到${NC}"
    fi

    echo -e "\n${CYAN}────────────────────────────────────────────${NC}"

    # 如果没有找到任何资源
    if [ -z "$matching_containers" ] && [ -z "$matching_images" ] && [ -z "$matching_networks" ] && [ -z "$matching_volumes" ]; then
        echo -e "${YELLOW}未找到与 '$service_keyword' 相关的任何资源${NC}"
        return
    fi

    echo -e "\n${RED}⚠️  确认彻底删除以上所有资源? (输入 'DELETE' 确认):${NC}"
    read -r confirm

    if [ "$confirm" != "DELETE" ]; then
        echo -e "${YELLOW}已取消删除${NC}"
        return
    fi

    echo -e "\n${YELLOW}🗑️  开始清除...${NC}\n"

    # 删除容器
    if [ -n "$matching_containers" ]; then
        echo -e "${BLUE}[1/4]${NC} 停止并删除容器..."
        echo "$matching_containers" | awk '{print $1}' | while read container_id; do
            docker stop "$container_id" 2>/dev/null
            docker rm -f "$container_id" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 已删除容器: $container_id"
        done
    fi

    # 删除镜像
    if [ -n "$matching_images" ]; then
        echo -e "\n${BLUE}[2/4]${NC} 删除镜像..."
        echo "$matching_images" | awk '{print $2}' | while read image_id; do
            docker rmi -f "$image_id" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 已删除镜像: $image_id"
        done
    fi

    # 删除网络
    if [ -n "$matching_networks" ]; then
        echo -e "\n${BLUE}[3/4]${NC} 删除网络..."
        echo "$matching_networks" | awk '{print $1}' | while read network_id; do
            docker network rm "$network_id" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 已删除网络: $network_id"
        done
    fi

    # 删除数据卷
    if [ -n "$matching_volumes" ]; then
        echo -e "\n${BLUE}[4/4]${NC} 删除数据卷..."
        echo "$matching_volumes" | while read volume_name; do
            docker volume rm "$volume_name" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 已删除数据卷: $volume_name"
        done
    fi

    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ 服务 '$service_keyword' 已彻底清除！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 21. 容器深度清理
deep_clean_container() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        💣 容器深度清理                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    echo -e "${RED}⚠️  此功能将深度清理指定容器的所有关联资源！${NC}"
    echo -e "${YELLOW}包括: 容器本身、使用的镜像、挂载的卷、关联的网络${NC}\n"

    echo -e "${YELLOW}📋 所有容器:${NC}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"

    echo -e "\n${BLUE}请输入要深度清理的容器名称或 ID:${NC}"
    read -r container_id

    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ 错误：容器名称或 ID 不能为空。${NC}"
        return
    fi

    # 检查容器是否存在
    if ! docker ps -a --format "{{.ID}}" | grep -q "^${container_id}"; then
        if ! docker ps -a --format "{{.Names}}" | grep -q "^${container_id}$"; then
            echo -e "${RED}❌ 错误：未找到容器 '$container_id'${NC}"
            return
        fi
    fi

    echo -e "\n${YELLOW}🔍 分析容器资源...${NC}\n"

    # 获取容器详细信息
    container_info=$(docker inspect "$container_id" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 错误：无法获取容器信息${NC}"
        return
    fi

    # 获取容器名称
    container_name=$(echo "$container_info" | grep -o '"Name": *"[^"]*"' | head -1 | cut -d'"' -f4)

    # 获取容器使用的镜像
    image_id=$(echo "$container_info" | grep -o '"Image": *"sha256:[^"]*"' | head -1 | cut -d'"' -f4)
    image_name=$(docker inspect --format='{{.Config.Image}}' "$container_id" 2>/dev/null)

    # 获取容器挂载的卷
    volumes=$(echo "$container_info" | grep -o '"Source": *"[^"]*"' | cut -d'"' -f4)
    named_volumes=$(docker inspect --format='{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' "$container_id" 2>/dev/null)

    # 获取容器连接的网络
    networks=$(docker inspect --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}' "$container_id" 2>/dev/null | grep -v "^bridge$" | grep -v "^host$" | grep -v "^none$")

    # 显示资源详情
    echo -e "${CYAN}📦 容器信息:${NC}"
    echo -e "  ID: ${YELLOW}${container_id}${NC}"
    echo -e "  名称: ${YELLOW}${container_name}${NC}"

    echo -e "\n${CYAN}🖼️  使用的镜像:${NC}"
    if [ -n "$image_name" ]; then
        echo -e "  ${YELLOW}${image_name}${NC} (${image_id:0:12})"
        # 检查是否有其他容器使用同一镜像
        other_containers=$(docker ps -a --filter "ancestor=$image_name" --format "{{.ID}}" | grep -v "^${container_id:0:12}" | wc -l | tr -d ' ')
        if [ "$other_containers" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠ 注意：还有 $other_containers 个容器使用此镜像${NC}"
        fi
    else
        echo -e "  ${YELLOW}未找到${NC}"
    fi

    echo -e "\n${CYAN}💾 挂载的数据卷:${NC}"
    if [ -n "$named_volumes" ]; then
        echo "$named_volumes" | while read vol; do
            if [ -n "$vol" ]; then
                # 检查是否有其他容器使用同一卷
                vol_usage=$(docker ps -a --filter "volume=$vol" --format "{{.ID}}" | grep -v "^${container_id:0:12}" | wc -l | tr -d ' ')
                if [ "$vol_usage" -gt 0 ]; then
                    echo -e "  ${YELLOW}$vol${NC} ${RED}(被 $vol_usage 个其他容器使用，不会删除)${NC}"
                else
                    echo -e "  ${YELLOW}$vol${NC}"
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}无命名卷${NC}"
    fi

    echo -e "\n${CYAN}🌐 连接的网络:${NC}"
    if [ -n "$networks" ]; then
        echo "$networks" | while read net; do
            if [ -n "$net" ]; then
                # 检查网络是否有其他容器使用
                net_usage=$(docker network inspect "$net" -f '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' 2>/dev/null | grep -v "^${container_name#/}$" | wc -l | tr -d ' ')
                if [ "$net_usage" -gt 0 ]; then
                    echo -e "  ${YELLOW}$net${NC} ${RED}(被 $net_usage 个其他容器使用，不会删除)${NC}"
                else
                    echo -e "  ${YELLOW}$net${NC}"
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}仅使用默认网络${NC}"
    fi

    echo -e "\n${CYAN}────────────────────────────────────────────${NC}"

    echo -e "\n${RED}⚠️  确认深度清理以上资源? (输入 'YES' 确认):${NC}"
    read -r confirm

    if [ "$confirm" != "YES" ]; then
        echo -e "${YELLOW}已取消清理${NC}"
        return
    fi

    echo -e "\n${YELLOW}💣 开始深度清理...${NC}\n"

    # 1. 停止并删除容器
    echo -e "${BLUE}[1/4]${NC} 停止并删除容器..."
    docker stop "$container_id" 2>/dev/null
    docker rm -f "$container_id" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} 已删除容器: $container_id"
    else
        echo -e "  ${RED}✗${NC} 删除容器失败"
    fi

    # 2. 删除镜像（如果没有其他容器使用）
    echo -e "\n${BLUE}[2/4]${NC} 清理镜像..."
    if [ -n "$image_name" ] && [ "$other_containers" -eq 0 ]; then
        docker rmi "$image_name" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} 已删除镜像: $image_name"
        else
            echo -e "  ${YELLOW}⚠${NC} 镜像删除失败或被其他资源使用"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} 跳过镜像删除（被其他容器使用或未找到）"
    fi

    # 3. 删除数据卷（仅删除未被其他容器使用的）
    echo -e "\n${BLUE}[3/4]${NC} 清理数据卷..."
    if [ -n "$named_volumes" ]; then
        deleted_volumes=0
        skipped_volumes=0
        echo "$named_volumes" | while read vol; do
            if [ -n "$vol" ]; then
                vol_usage=$(docker ps -a --filter "volume=$vol" --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ')
                if [ "$vol_usage" -eq 0 ]; then
                    docker volume rm "$vol" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "  ${GREEN}✓${NC} 已删除数据卷: $vol"
                    fi
                else
                    echo -e "  ${YELLOW}⚠${NC} 跳过数据卷: $vol (被其他容器使用)"
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}⚠${NC} 无需清理数据卷"
    fi

    # 4. 删除网络（仅删除未被其他容器使用的）
    echo -e "\n${BLUE}[4/4]${NC} 清理网络..."
    if [ -n "$networks" ]; then
        echo "$networks" | while read net; do
            if [ -n "$net" ]; then
                net_usage=$(docker network inspect "$net" -f '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' 2>/dev/null | wc -l | tr -d ' ')
                if [ "$net_usage" -eq 0 ]; then
                    docker network rm "$net" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "  ${GREEN}✓${NC} 已删除网络: $net"
                    fi
                else
                    echo -e "  ${YELLOW}⚠${NC} 跳过网络: $net (被其他容器使用)"
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}⚠${NC} 无需清理网络"
    fi

    # 5. 清理所有未使用的残余资源
    echo -e "\n${BLUE}[额外]${NC} 清理所有未使用的残余资源..."
    echo -e "  ${CYAN}•${NC} 清理悬空镜像..."
    docker image prune -f 2>/dev/null
    echo -e "  ${CYAN}•${NC} 清理未使用的网络..."
    docker network prune -f 2>/dev/null
    echo -e "  ${CYAN}•${NC} 清理未使用的数据卷..."
    docker volume prune -f 2>/dev/null

    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ 容器深度清理完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "\n${YELLOW}📊 当前磁盘使用情况:${NC}\n"
    docker system df
}

# 18. 执行 Docker Compose
run_docker_compose() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🔧 执行 Docker Compose              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

    if [ -z "$COMPOSE_CMD" ]; then
        echo -e "${RED}❌ 错误: Docker Compose 未安装或不可用。${NC}"
        return
    fi

    echo -e "${BLUE}请输入 docker-compose.yml 所在目录的路径 (默认为当前目录 '.'):${NC}"
    read -r compose_path
    compose_path=${compose_path:-.}

    if [ -d "$compose_path" ]; then
        echo -e "\n${YELLOW}🔧 正在目录 \"$compose_path\" 中执行: $COMPOSE_CMD up -d${NC}\n"
        (cd "$compose_path" && $COMPOSE_CMD up -d)
    else
        echo -e "${RED}❌ 错误: 目录 \"$compose_path\" 不存在。${NC}"
    fi
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                  ║${NC}"
    echo -e "${GREEN}║       🐳 Docker 交互式操作菜单 v4 ($OS)       ║${NC}"
    echo -e "${GREEN}║                                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}┌─ 📦 容器操作 ────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}1.${NC}  构建镜像                  ${YELLOW}6.${NC}  查看日志              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}2.${NC}  运行容器                  ${YELLOW}7.${NC}  进入容器              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}3.${NC}  停止容器                  ${YELLOW}8.${NC}  删除容器              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}4.${NC}  启动容器                                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}5.${NC}  重启容器                                          ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}┌─ 📋 镜像 & 列表 ─────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}9.${NC}  查看运行中的容器          ${YELLOW}12.${NC} 拉取镜像              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}10.${NC} 查看所有容器              ${YELLOW}13.${NC} 删除镜像              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}11.${NC} 查看本地镜像                                      ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}┌─ 🧹 系统维护 ────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}14.${NC} 资源监控                  ${YELLOW}17.${NC} 服务彻底清除          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}15.${NC} 磁盘使用分析              ${YELLOW}21.${NC} 容器深度清理          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}16.${NC} 系统清理                                          ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}┌─ 🔧 Compose & 工具 ──────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}18.${NC} 执行 Docker Compose       ${YELLOW}20.${NC} 删除快捷指令          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}19.${NC} 安装快捷指令 (输入 'dk' 运行本脚本)              ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${RED}  0.${NC}  退出脚本"
    echo ""
    echo -n -e "${BLUE}请输入您的选择 [0-21]: ${NC}"
}

# 主循环
while true; do
    show_menu
    read -r choice
    case $choice in
        1) build_image; press_any_key_to_continue ;;
        2) run_container; press_any_key_to_continue ;;
        3) stop_container; press_any_key_to_continue ;;
        4) start_container; press_any_key_to_continue ;;
        5) restart_container; press_any_key_to_continue ;;
        6) view_logs; press_any_key_to_continue ;;
        7) exec_container; press_any_key_to_continue ;;
        8) remove_container; press_any_key_to_continue ;;
        9) list_running_containers; press_any_key_to_continue ;;
        10) list_all_containers; press_any_key_to_continue ;;
        11) list_images; press_any_key_to_continue ;;
        12) pull_image; press_any_key_to_continue ;;
        13) remove_image; press_any_key_to_continue ;;
        14) monitor_resources; press_any_key_to_continue ;;
        15) disk_usage_analysis; press_any_key_to_continue ;;
        16) system_cleanup; press_any_key_to_continue ;;
        17) complete_removal; press_any_key_to_continue ;;
        18) run_docker_compose; press_any_key_to_continue ;;
        19) install_shortcut; press_any_key_to_continue ;;
        20) uninstall_shortcut; press_any_key_to_continue ;;
        21) deep_clean_container; press_any_key_to_continue ;;
        0) echo -e "\n${GREEN}👋 感谢使用，再见！${NC}\n";
           break ;;
        *) echo -e "\n${RED}❌ 无效输入，请输入 0 到 21 之间的数字。${NC}"; press_any_key_to_continue ;;
    esac
done

# 脚本正常退出，保持终端打开
exit 0
