/*
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package statecouchdb

import (
	"encoding/base64"

	"github.com/golang/protobuf/proto"
	"github.com/hyperledger/fabric/core/ledger/internal/version"
	"github.com/hyperledger/fabric/core/ledger/kvledger/txmgmt/statedb"
	"github.com/pkg/errors"
)

func encodeVersionAndMetadata(version *version.Height, metadata []byte, ns, key string) (string, error) {
	if version == nil {
		return "", errors.New("nil version not supported")
	}
	encryptedMetadata := statedb.EncryptValue(metadata, ns, key)
	msg := &VersionAndMetadata{
		Version:  version.ToBytes(),
		Metadata: encryptedMetadata,
	}
	msgBytes, err := proto.Marshal(msg)
	if err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(msgBytes), nil
}

func decodeVersionAndMetadata(encodedstr string, ns, key string) (*version.Height, []byte, error) {
	persistedVersionAndMetadata, err := base64.StdEncoding.DecodeString(encodedstr)
	if err != nil {
		return nil, nil, err
	}
	versionAndMetadata := &VersionAndMetadata{}
	if err = proto.Unmarshal(persistedVersionAndMetadata, versionAndMetadata); err != nil {
		return nil, nil, err
	}
	ver, _, err := version.NewHeightFromBytes(versionAndMetadata.Version)
	if err != nil {
		return nil, nil, err
	}
	decryptedMetadata := statedb.DecryptValue(versionAndMetadata.Metadata, ns, key)
	return ver, decryptedMetadata, nil
}
