<template>
  <div class="container home">
    <!-- Open a packet -->
    <el-card ref="red-packet-box" class="red-packet-box" v-if="waitToOpenPack.uuid">
      <i @click="$router.replace({ name: 'Home' })" class="el-icon-close"></i>
      <div v-if="waitToOpenPack.merkle_root">
        <h2>Packet to open</h2>
        <p>Packet packed with token: {{ waitToOpenPack.token_identifier.split('::').pop() }}</p>
        <el-button type="danger" size="large" @click="openPacket" v-if="packetCanOpen">
          OPEN!
        </el-button>
        <el-button size="small" disabled v-else>Packet Already Opened</el-button>
      </div>
      <div v-else>
        <p class="hints">
          The packet does not exist already! The packet info will be updated in 5 seconds
        </p>
      </div>
    </el-card>

    <!-- Create New Packet -->
    <el-card class="packet-form">
      <el-form ref="packet-form" :model="packet">
        <h2>Pack A Packet</h2>
        <el-form-item
          label="Token: "
          prop="token_identifier"
          :rules="[
            {
              required: true,
              message: 'Select a token type!',
              trigger: ['change', 'blur'],
            },
          ]"
        >
          <el-select v-model="packet.token_identifier">
            <el-option
              v-for="(resource, index) in resourcesList"
              :key="index"
              :label="resource.name"
              :value="index"
              value-key="name"
            >
              <span class="token-option">
                {{ resource.name }}
                <em>{{ resource.amount }}</em>
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item
          label="Total: "
          prop="token_amount"
          :rules="[
            {
              required: true,
              type: 'number',
              trigger: ['change', 'blur'],
              validator: (rule, value, callback) => {
                if (isNaN(value)) {
                  return callback('Please enter a number!');
                }

                if (value > currentTokenAmount || value <= 0) {
                  return callback(
                    'Please enter a number less than or equal to the current token amount!',
                  );
                }
                return callback();
              },
            },
          ]"
        >
          <p>Max: {{ currentTokenAmount }}</p>
          <el-input v-model.number="packet.token_amount" :max="currentTokenAmount">
            <template slot="append">{{ currentTokenType }}</template>
          </el-input>
        </el-form-item>
        <el-form-item
          label="Quantity: "
          prop="quantity"
          :rules="[
            {
              required: true,
              type: 'integer',
              message: 'Please enter the integer number of splits!',
              trigger: ['change', 'blur'],
            },
          ]"
        >
          <el-input v-model.number="packet.quantity"></el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="pack">Pack It !</el-button>
        </el-form-item>
      </el-form>

      <div class="share-box" v-if="shareLink" style="word-break: break-all">
        <h3>Share This Link to friends to open the packet</h3>
        <a :href="shareLink" target="_blank">{{ shareLink }}</a>
        <vue-qrcode :value="shareLink" />
      </div>
    </el-card>

    <!-- Txns 列表 -->
    <el-card class="txn-list">
      <el-table :data="$txnList">
        <el-table-column prop="txn" label="Txns">
          <template slot-scope="scope">
            <p>
              <i class="el-icon-watch"></i>
              {{ scope.row.time }}
            </p>
            <a
              :href="`https://stcscan.io/barnard/transactions/detail/${scope.row.txn}`"
              target="_blank"
            >
              <i class="el-icon-link"></i>
              {{ scope.row.txn }}
            </a>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Cancel Packets -->
    <el-card class="cancel-box">
      <h2>Cancel Token Packets</h2>
      <p class="hints">
        This operation will always cost gas fee whether you had created any packets of selected
        token.
      </p>
      <el-form inline>
        <el-form-item>
          <el-select size="small" v-model="tokenOfCancelPackets" clearable>
            <el-option
              v-for="(resource, index) in resourcesList"
              :key="index"
              :label="resource.name"
              :value="resource.tokenName"
              value-key="name"
            >
              <span class="token-option">
                {{ resource.name }}
                <em>{{ resource.amount }}</em>
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button
            size="small"
            type="danger"
            @click="cancelPacket"
            :disabled="!tokenOfCancelPackets"
          >
            Cancel
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
  import { mapActions, mapGetters } from 'vuex';

  import {
    Account_Info,
    CreatePacket,
    ClaimPacket,
    CheckPacket,
    CancelPacket,
  } from 'utils/Provider';
  import VueQrcode from 'vue-qrcode';

  export default {
    name: 'Home',
    data() {
      return {
        packet: {},
        resourcesList: [],
        packing: false,
        shareLink: '',
        waitToOpenPack: {},
        tokenOfCancelPackets: '',
      };
    },
    components: {
      VueQrcode,
    },
    computed: {
      currentTokenType() {
        if (this.packet.token_identifier) {
          return this.resourcesList[this.packet.token_identifier].name.toUpperCase();
        }
        return 'STC';
      },
      currentTokenAmount() {
        if (typeof this.packet.token_identifier !== 'undefined') {
          return this.resourcesList[this.packet.token_identifier].amount;
        }
        return 0;
      },
      packetCanOpen() {
        const { claimed, leafs } = this.waitToOpenPack;
        if (leafs) {
          return claimed.length !== leafs.length && !claimed.includes(this.$accountHash);
        }
        return false;
      },
      ...mapGetters(['$accountHash', '$txnList']),
    },
    watch: {
      $accountHash() {
        if (this.$accountHash) {
          Account_Info(this.$accountHash).then((res) => {
            this.resourcesList = res;
          });
          this.initQuery();
        }
      },
      $route() {
        this.initQuery();
      },
    },
    created() {
      if (this.$accountHash) {
        this.refreshAccountInfo();
        this.initQuery();
      }
    },
    methods: {
      refreshAccountInfo() {
        Account_Info(this.$accountHash).then((res) => {
          this.resourcesList = res;
        });
      },
      /**
       * @function initQuery
       *
       * Init packet
       */
      initQuery() {
        const { s } = this.$route.query;
        this.waitToOpenPack = {};

        try {
          if (!s) return;
          this.waitToOpenPack = {
            ...this.waitToOpenPack,
            ...JSON.parse(window.atob(s)),
          };
          let loadingInstance = null;
          // pack dom loading
          this.$nextTick(() => {
            loadingInstance = this.$loading({
              target: this.$refs['red-packet-box'].$el,
              text: 'Loading Packet...',
            });
          });

          if (this.waitToOpenPack.token_identifier) {
            return CheckPacket({
              account: this.waitToOpenPack.owner_address,
              uuid: this.waitToOpenPack.uuid,
              token_identifier: this.waitToOpenPack.token_identifier,
            }).then((res) => {
              this.waitToOpenPack = {
                ...this.waitToOpenPack,
                ...res,
              };

              if (!this.waitToOpenPack.merkle_root) {
                setTimeout(() => {
                  this.initQuery();
                }, 5e3);
              }
              loadingInstance.close();
            });
          }
          loadingInstance.close();
          return Promise.resolve();
        } catch (err) {
          console.log('query has error');
        }
      },
      /**
       * @function pack
       */
      pack() {
        if (this.packing) return;
        this.$refs['packet-form'].validate((valid) => {
          if (valid) {
            this.packing = true;
            this.$loading();

            CreatePacket({
              quantity: this.packet.quantity,
              token_amount: this.packet.token_amount * Math.pow(10, 9),
              token_identifier: this.resourcesList[this.packet.token_identifier].tokenName,
            })
              .then((result) => {
                const { txn, ...res } = result;
                const sParams = window.btoa(
                  JSON.stringify({
                    ...res,
                    token_identifier: this.resourcesList[this.packet.token_identifier].tokenName,
                    owner_address: this.$accountHash,
                  }),
                );

                this.$addTxn(txn);

                this.shareLink = `${window.location.origin}/${
                  this.$router.resolve({
                    name: 'Home',
                    query: {
                      s: sParams,
                    },
                  }).href
                }`;

                this.$refs['packet-form'].resetFields();
                this.refreshAccountInfo();
                this.$message.success('Packet Request Has been Submit');
              })
              .finally(() => {
                this.packing = false;
                this.$loading().close();
              });
          }
        });
      },
      /**
       * @function openPacket
       */
      openPacket() {
        if (this.waitToOpenPack.uuid) {
          this.$loading();
          ClaimPacket(this.waitToOpenPack)
            .then((txn) => {
              // save this txn
              this.$addTxn(txn);
              this.$message.success('Packet Has been Claimed');
              this.refreshAccountInfo();
              return this.initQuery();
            })
            .catch((err) => {})
            .finally(() => {
              this.$loading().close();
            });
        }
      },
      /**
       * @function cancelPacket
       */
      cancelPacket() {
        if (this.tokenOfCancelPackets) {
          this.$prompt(
            `<p>Are you sure to cancel these packets of ${this.tokenOfCancelPackets} ?</p><p style="color: #f60000">Please enter you account to confirm: </p>`,
            'Cancel Packets',
            { dangerouslyUseHTMLString: true },
          )
            .then(({ value }) => {
              if (value.toLowerCase() === this.$accountHash.toLowerCase()) {
                this.$loading();
                CancelPacket({
                  token_identifier: this.tokenOfCancelPackets,
                })
                  .then((txn) => {
                    this.tokenOfCancelPackets = '';
                    this.$addTxn(txn);
                    this.refreshAccountInfo();
                    this.$message.success(
                      `Cancele Request Packets of ${this.tokenOfCancelPackets} has been submited `,
                    );
                  })
                  .finally(() => {
                    this.$loading().close();
                  });
              } else {
                this.$message.error(`You have entered a wrong account!`);
              }
            })
            .catch(() => {});
        }
      },
      ...mapActions(['$addTxn', '$cleanTxn']),
    },
  };
</script>

<style lang="less" scoped>
  .home {
    padding: 5px 0;
    font-size: 12px;
    display: flex;
    flex-wrap: wrap;
    flex-direction: column;

    .packet-form,
    .red-packet-box,
    .txn-list,
    .cancel-box {
      width: 400px;
      max-width: 100%;
      margin: 20px auto;
      h2 {
        margin: 10px 0;
      }
    }

    .red-packet-box {
      word-break: break-all;
      border-radius: 8px;
      position: relative;
      min-height: 120px;
      p {
        margin: 10px 0;
      }

      .el-icon-close {
        position: absolute;
        right: 10px;
        top: 10px;
        font-size: 14px;
        cursor: pointer;
      }
    }

    .share-box {
      a {
        color: gray;
        text-decoration: underline;
        margin: 10px 0;
        display: block;
      }

      img {
        margin: 0 auto;
        display: block;
      }
    }
  }

  .hints {
    font-size: 12px;
    color: #f14646;
    margin-bottom: 10px;
  }

  .token-option {
    display: flex;
    font-size: 14px;
    em {
      font-weight: bolder;
      margin-left: auto;
      font-style: normal;
    }
  }
</style>
