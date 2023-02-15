Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
Wallet_name=""
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_celestia(){
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y

    ver="1.19.1"
    cd $HOME
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"

    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile

    go version

    cd $HOME
    rm -rf celestia-node
    git clone https://github.com/celestiaorg/celestia-node.git
    cd celestia-node/
    git checkout tags/v0.6.0
    make install

    celestia version
    celestia light init

    echo "celestia 安装并运行"
}

create_wallet(){
    cd $HOME
    cd celestia-node/

    make cel-key
    source $HOME/.cargo/env
    read -p " 请输入钱包名字:" name
    echo "你输入的钱包名字是 $name"
    read -r -p "请确认输入的钱包名字正确，正确请输入Y，否则将退出 [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo "继续安装"
            ;;

        *)
            echo "退出安装..."
            exit 1
            ;;
    esac
    WALLETNAME=$name
    echo export WALLET_NAME=$WALLETNAME >> /etc/profile
    source /etc/profile
    ./cel-key add $name --keyring-backend test --node.type light

    echo "创建钱包成功，请保管好助记词和钱包地址！"
    cd $HOME
}

run_celestia(){
    celestia light start --core.ip https://rpc-mocha.pops.one --core.grpc.port 9090
    echo "启动轻节点成功！"
    echo "请去 discord #mocha-facut频道领取测试币"
}

setupclient_celestia(){
    cd $HOME
    rm -rf celestia-app
    git clone https://github.com/celestiaorg/celestia-app.git
    cd celestia-app/
    APP_VERSION=v0.11.0
    git checkout tags/$APP_VERSION -b $APP_VERSION
    make install
    sleep 5
    echo "安装客户端成功！"
}

import_celestia(){
    celestia-appd config keyring-backend test

    echo "请导入助记词"

    celestia-appd keys add $WALLETNAME --recover

    echo "导入助记词成功"
}

stake_celestia(){
    celestia-appd tx staking delegate celestiavaloper1msglwkyaxl9zm92tkmve4cgwcanptlexjtzex2 5000000utia --from=$WALLETNAME --fees 300utia --chain-id=mocha --node https://rpc-mocha.pops.one:443
    echo "委托质押成功"
}

echo && echo -e " ${Red_font_prefix}celestia 一键脚本${Font_color_suffix} by \033[1;35mLattice\033[0m
此脚本完全免费开源，由推特用户 ${Green_font_prefix}@ourbtc${Font_color_suffix} 二次开发并升级
欢迎关注，如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装并运行 celestia ${Font_color_suffix}
 ${Green_font_prefix} 2.创建钱包 ${Font_color_suffix}
 ${Green_font_prefix} 3.启动 celestia 节点 ${Font_color_suffix}
 ${Green_font_prefix} 4.安装 celestia 客户端 ${Font_color_suffix}
 ${Green_font_prefix} 5.请导入助记词 ${Font_color_suffix}
 ${Green_font_prefix} 6.执行委托质押 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1-6]:" num
case "$num" in
1)
    install_celestia
    ;;
2)
    create_wallet
    ;;
3)
    run_celestia
    ;;
4)
    setupclient_celestia
    ;;
5)
    import_celestia
    ;;
6)
    stake_celestia
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac