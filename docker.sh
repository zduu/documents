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
    local script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local bin_dir="$HOME/.local/bin"
    local shortcut_name="dk"

    # 创建 bin 目录
    mkdir -p "$bin_dir"

    # 创建软链接
    ln -sf "$script_path" "$bin_dir/$shortcut_name"

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
        if ! grep -q "$bin_dir" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Docker 脚本快捷指令" >> "$shell_rc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            echo -e "${GREEN}✓ 已添加 PATH 到 $shell_rc${NC}"
        fi
    fi

    echo -e "\n${GREEN}✓ 快捷指令安装成功！${NC}"
    echo -e "${YELLOW}快捷指令: ${CYAN}dk${NC}"
    echo -e "${YELLOW}请运行以下命令使其生效:${NC}"
    echo -e "${CYAN}  source $shell_rc${NC}"
    echo -e "${YELLOW}或者重新打开终端${NC}"
    echo -e "\n${YELLOW}之后可以在任何位置直接运行: ${CYAN}dk${NC}"
}

# 通用函数：提示按任意键继续
press_any_key_to_continue() {
    echo -e "\n${YELLOW}按任意键返回主菜单...${NC}"
    read -n 1 -s -r
}

# 1. 构建镜像
build_image() {
    echo -e "\n${CYAN}--- 1. 构建镜像 ---${NC}"
    echo -e "${BLUE}请输入镜像标签 (例如: my-app:1.0):${NC}"
    read -r image_tag
    if [ -z "$image_tag" ]; then
        echo -e "${RED}错误：镜像标签不能为空。${NC}"
        return
    fi

    echo -e "${BLUE}请输入 Dockerfile 所在目录的路径 (默认为当前目录 '.'):${NC}"
    read -r dockerfile_path
    dockerfile_path=${dockerfile_path:-.}

    echo -e "\n${YELLOW}正在执行: docker build -t \"$image_tag\" \"$dockerfile_path\"${NC}\n"
    docker build -t "$image_tag" "$dockerfile_path"
}

# 2. 运行容器
run_container() {
    echo -e "\n${CYAN}--- 2. 运行容器 ---${NC}"
    echo -e "${YELLOW}--- 本地镜像列表 ---${NC}"
    docker images
    echo -e "--------------------"
    echo -e "${BLUE}请输入要运行的镜像名称 (例如: my-app:1.0):${NC}"
    read -r image_name
    if [ -z "$image_name" ]; then
        echo -e "${RED}错误：镜像名称不能为空。${NC}"
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

    echo -e "\n${YELLOW}正在执行: docker run $detach_arg $port_arg $name_arg $image_name${NC}\n"
    docker run $detach_arg $port_arg $name_arg "$image_name"
}

# 3. 停止容器
stop_container() {
    echo -e "\n${CYAN}--- 3. 停止容器 ---${NC}"
    echo -e "${YELLOW}--- 正在运行的容器 ---${NC}"
    docker ps
    echo -e "--------------------"
    echo -e "${BLUE}请输入要停止的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}正在执行: docker stop \"$container_id\"${NC}\n"
    docker stop "$container_id"
}

# 4. 启动已停止的容器
start_container() {
    echo -e "\n${CYAN}--- 4. 启动容器 ---${NC}"
    echo -e "${YELLOW}--- 所有已停止的容器 ---${NC}"
    docker ps -f "status=exited"
    echo -e "--------------------"
    echo -e "${BLUE}请输入要启动的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}正在执行: docker start \"$container_id\"${NC}\n"
    docker start "$container_id"
}

# 8. 删除容器
remove_container() {
    echo -e "\n${CYAN}--- 8. 删除容器 ---${NC}"
    echo -e "${YELLOW}--- 所有容器 (包括已停止的) ---${NC}"
    docker ps -a
    echo -e "--------------------"
    echo -e "${BLUE}请输入要删除的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}正在执行: docker rm \"$container_id\"${NC}\n"
    docker rm "$container_id"
}

# 9. 删除镜像
remove_image() {
    echo -e "\n${CYAN}--- 9. 删除镜像 ---${NC}"
    echo -e "${YELLOW}--- 本地镜像列表 ---${NC}"
    docker images
    echo -e "--------------------"
    echo -e "${BLUE}请输入要删除的镜像名称或 ID:${NC}"
    read -r image_id
    if [ -z "$image_id" ]; then
        echo -e "${RED}错误：镜像名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}正在执行: docker rmi \"$image_id\"${NC}\n"
    docker rmi "$image_id"
}

# 10. 查看容器日志
view_logs() {
    echo -e "\n${CYAN}--- 10. 查看容器日志 ---${NC}"
    echo -e "${YELLOW}--- 正在运行的容器 ---${NC}"
    docker ps
    echo -e "--------------------"
    echo -e "${BLUE}请输入要查看日志的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    echo -e "\n${YELLOW}正在执行: docker logs -f \"$container_id\"${NC}"
    echo -e "${YELLOW}(按 Ctrl+C 停止查看日志)${NC}\n"
    docker logs -f "$container_id"
}

# 11. 进入容器
exec_container() {
    echo -e "\n${CYAN}--- 11. 进入容器 ---${NC}"
    echo -e "${YELLOW}--- 正在运行的容器 ---${NC}"
    docker ps
    echo -e "--------------------"
    echo -e "${BLUE}请输入要进入的容器名称或 ID:${NC}"
    read -r container_id
    if [ -z "$container_id" ]; then
        echo -e "${RED}错误：容器名称或 ID 不能为空。${NC}"
        return
    fi
    
    echo -e "${BLUE}请输入要执行的命令 (默认为 /bin/bash):${NC}"
    read -r command
    command=${command:-/bin/bash}

    echo -e "\n${YELLOW}正在执行: docker exec -it \"$container_id\" $command${NC}\n"
    docker exec -it "$container_id" $command
}

# 12. 执行 Docker Compose
run_docker_compose() {
    echo -e "\n${CYAN}--- 12. 执行 Docker Compose ---${NC}"

    if [ -z "$COMPOSE_CMD" ]; then
        echo -e "${RED}错误: Docker Compose 未安装或不可用。${NC}"
        return
    fi

    echo -e "${BLUE}请输入 docker-compose.yml 所在目录的路径 (默认为当前目录 '.'):${NC}"
    read -r compose_path
    compose_path=${compose_path:-.}

    if [ -d "$compose_path" ]; then
        echo -e "\n${YELLOW}正在目录 \"$compose_path\" 中执行: $COMPOSE_CMD up -d${NC}\n"
        (cd "$compose_path" && $COMPOSE_CMD up -d)
    else
        echo -e "${RED}错误: 目录 \"$compose_path\" 不存在。${NC}"
    fi
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}        Docker 交互式操作菜单 v3 ($OS)        ${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo -e " ${CYAN}容器操作:${NC}"
    echo -e "  ${YELLOW}1.${NC} 构建镜像 (Build)"
    echo -e "  ${YELLOW}2.${NC} 运行容器 (Run)"
    echo -e "  ${YELLOW}3.${NC} 停止容器 (Stop)"
    echo -e "  ${YELLOW}4.${NC} 启动容器 (Start)"
    echo -e "  ${YELLOW}10.${NC} 查看日志 (Logs)"
    echo -e "  ${YELLOW}11.${NC} 进入容器 (Exec)"
    echo
    echo -e " ${CYAN}列表与清理:${NC}"
    echo -e "  ${YELLOW}5.${NC} 查看运行中的容器 (ls)"
    echo -e "  ${YELLOW}6.${NC} 查看所有容器 (ls -a)"
    echo -e "  ${YELLOW}7.${NC} 查看本地镜像 (images)"
    echo -e "  ${YELLOW}8.${NC} 删除容器 (rm)"
    echo -e "  ${YELLOW}9.${NC} 删除镜像 (rmi)"
    echo
    echo -e " ${CYAN}Compose:${NC}"
    echo -e "  ${YELLOW}12.${NC} 执行 Docker Compose (up -d)"
    echo
    echo -e " ${CYAN}工具:${NC}"
    echo -e "  ${YELLOW}13.${NC} 安装快捷指令 (输入 'dk' 即可运行本脚本)"
    echo
    echo -e " ${RED}0. 退出脚本 (Exit)${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${BLUE}请输入您的选择 [0-13]:${NC}"
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
        5) echo -e "\n${CYAN}--- 5. 正在运行的容器 ---${NC}"; docker ps; press_any_key_to_continue ;;
        6) echo -e "\n${CYAN}--- 6. 所有容器 (包括已停止的) ---${NC}"; docker ps -a; press_any_key_to_continue ;;
        7) echo -e "\n${CYAN}--- 7. 本地镜像列表 ---${NC}"; docker images; press_any_key_to_continue ;;
        8) remove_container; press_any_key_to_continue ;;
        9) remove_image; press_any_key_to_continue ;;
        10) view_logs; press_any_key_to_continue ;;
        11) exec_container; press_any_key_to_continue ;;
        12) run_docker_compose; press_any_key_to_continue ;;
        13) install_shortcut; press_any_key_to_continue ;;
        0) echo -e "\n${GREEN}感谢使用，正在退出...${NC}"; exit 0 ;;
        *) echo -e "\n${RED}无效输入，请输入 0 到 13 之间的数字。${NC}"; press_any_key_to_continue ;;
    esac
done
